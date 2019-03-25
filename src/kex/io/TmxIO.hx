package kex.io;

import format.tmx.Data;
import format.tmx.Reader;

using tink.CoreApi;

// TODO (DK) also load TX and images
class TmxIO extends GenericIO<TmxMap> {
	var blobs: BlobIO;
	var tsx: TsxIO;

	public function new( blobs: BlobIO ) {
		super('tmx');
		this.blobs = blobs;
		this.tsx = new TsxIO(blobs);
	}

	override function onResolve( scope: String, path: String, file: String ) : Promise<TmxMap> {
		return blobs.get(scope, path, file)
			.next(function( blob ) {
				var txt = blob.toString();
				var xml = Xml.parse(txt);
				var r = new Reader();
				var tmx = r.read(xml);
				return tmx;
			}).next(function( tmx ) {
				return Promise.inSequence([
					for (todo in tmx.tilesets) {
						tsx.get(scope, path, todo.source)
							.next(function( tset ) {
								format.tmx.Tools.applyTSX(tset, todo);
								return Noise;
							});
					}
				]).next(function( _ ) {
					return tmx;
				});
			});
	}
}
