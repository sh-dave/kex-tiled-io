package kex.io;

import format.tmx.Data;
import format.tmx.Reader;

using tink.CoreApi;

class TsxIO extends GenericIO<TmxTileset> {
	var blobs: BlobIO;

	public function new( blobs: BlobIO ) {
		super('tsx');
		this.blobs = blobs;
	}

	override function onResolve( scope: String, path: String, file: String ) : Promise<TmxTileset> {
		return blobs.get(scope, path, file)
			.next(function( blob ) {
				var txt = blob.toString();
				var xml = Xml.parse(txt);
				var map = new Reader().readTSX(xml);
				return map;
			});
	}
}
