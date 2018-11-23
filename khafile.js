let project = new Project('kex-tiled-io');
project.addLibrary('haxe-format-tiled');
project.addLibrary('kex-io');
project.addSources('src');
resolve(project);
