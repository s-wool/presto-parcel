#!/bin/sh

pushd .
cd ${project.build.directory}

parcel_name="${project.artifactId}-${presto.version}"
mkdir $parcel_name

jdk_download_url="http://download.oracle.com/otn-pub/java/jdk/${jdk.version}-${jdk.build}/jdk-${jdk.version}-linux-x64.tar.gz"
jdk_download_name="jdk.tar.gz"
curl -L -o $jdk_download_name -H "Cookie: oraclelicense=accept-securebackup-cookie" $jdk_download_url
decompressed_dir="extract"
mkdir $decompressed_dir
tar xzf $jdk_download_name -C $decompressed_dir
mv $decompressed_dir/$(\ls $decompressed_dir) $parcel_name/jdk
rm -rf $decompressed_dir


presto_download_name="presto.tar.gz"
presto_download_url="https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${presto.version}/presto-server-${presto.version}.tar.gz"

curl -L -o $presto_download_name $presto_download_url
mkdir $decompressed_dir
tar xzf $presto_download_name -C $decompressed_dir

presto_dir=`\ls $decompressed_dir`
for file in `\ls $decompressed_dir/$presto_dir`; do
  mv $decompressed_dir/$presto_dir/$file $parcel_name
done
rm -rf $decompressed_dir

presto_cli_download_url="https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${presto.version}/presto-cli-${presto.version}-executable.jar"

curl -L -O $presto_cli_download_url
mv presto-cli-${presto.version}-executable.jar ${parcel_name}/bin/
chmod +x ${parcel_name}/bin/presto-cli-${presto.version}-executable.jar

cat <<"EOF" > ${parcel_name}/bin/presto
#!/usr/bin/env python

import os
import sys
import subprocess
from os.path import realpath, dirname

path = dirname(realpath(sys.argv[0]))
arg = ' '.join(sys.argv[1:])
cmd = "env PATH=\"%s/../jdk/bin:$PATH\" %s/presto-cli-${presto.version}-executable.jar %s" % (path, path, arg)

subprocess.call(cmd, shell=True)
EOF
chmod +x ${parcel_name}/bin/presto

cp -a ${project.build.outputDirectory}/meta ${parcel_name}
tar zcf ${parcel_name}.parcel ${parcel_name}/ --owner=root --group=root

mkdir repository
for i in el5 el6 sles11 lucid precise squeeze wheezy; do
  cp ${parcel_name}.parcel repository/${parcel_name}-${i}.parcel
done

cd repository
curl https://raw.githubusercontent.com/cloudera/cm_ext/master/make_manifest/make_manifest.py | python

popd
