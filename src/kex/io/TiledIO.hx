package kex.io;

import format.tmx.Data;
import format.tmx.Reader;
import kex.io.AssetLog.*;

using tink.CoreApi;

class TiledIO {
	var blobs: BlobIO;
	var cachedAssets: Map<String, TmxMap> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<TmxMap, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	public function new( blobs: BlobIO ) {
		this.blobs = blobs;
	}

	public function get( scope: String, path: String, file: String ) : Promise<TmxMap> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('queue map `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached map `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading map `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading map `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		return blobs.get(scope, path, file)
			.next(function( blob ) {
				try {
					var txt = blob.toString();
					var xml = Xml.parse(txt);
					var map = new Reader().read(xml);

					cachedAssets.set(url, map);
					var r = Success(map);

					for (t in loadingAssets.get(url)) {
						t.trigger(r);
					}

					loadingAssets.remove(url);
					return r;
				} catch (x: Dynamic) {
					var r = Failure(new Error(Std.string(x)));

					for (t in loadingAssets.get(url)) {
						t.trigger(r);
					}

					loadingAssets.remove(url);
					return r;
				}
			});
	}

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes.indexOf(scope) != -1) {
				unload(scope, url);
			}
		}
	}

	function unload( scope: String, url: String ) {
		var scopes = urlToScope.get(url);

		asset_info('unscoping map `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading map `$url`');
			cachedAssets.remove(url);
			blobs.unloadBlob(scope, url);
		}
	}
}
