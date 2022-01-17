#!/bin/bash
this_script_path=`realpath $0`
this_script_name=`basename $this_script_path`
this_script_dir=`dirname $this_script_path`
projroot=`realpath ${this_script_dir}/../`

. ${this_script_dir}/env.sh

old_wd=`pwd`
cd ${projroot}

export version=`git describe | sed -e 's/^[a-z,A-Z]*//g'`

echo "Get deps..."
mix deps.get || exit -1
echo "Building elixir release..."

MIX_ENV=prod mix release --overwrite || exit -1

echo "Building archive ${projroot}/_build/${app_name}.tar.gz"
tar -C _build/prod/rel \
  -czf ${projroot}/_build/${app_name}.tar.gz \
  ${app_name}

cd ${old_wd}

echo "Release complete."
