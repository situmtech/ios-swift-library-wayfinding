#!/usr/bin/env bash

# Comprobamos o parametro e asignamolo
ZIP_NAME="SitumWayfinding.appledoc.zip"
if [ ! -z "$1" ]; then
  ZIP_NAME=$1
fi

# Limpamos a carpeta de posibles execucions anteriores
if [ -d "docs/" ]; then
  if [ ! -z "$(ls -A docs)" ]; then
    rm -r docs/*
  fi
fi

if [ ! -d "docs/" ]; then
  mkdir docs/
fi

# Xeramos a documentacion no directorio {project_dir}/build/Documentation
count=`jazzy --podspec SitumWayfinding.podspec | grep -i 100% | wc -l`
if [ $count -lt 1 ]; then
    cat docs/undocumented.json # mostramos nos logs que partes non están documentadas
    echo "Documentation error. Either a public interface has not been documented, or a private interface has not been excluded"
    exit 1
fi

# Comprimimos nun zip o resultado
zip -r $ZIP_NAME ./docs/*
echo "Your appledoc was generated in <project_root>/${ZIP_NAME}"
