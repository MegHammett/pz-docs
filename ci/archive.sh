#!/bin/bash
set -e

# shellcheck disable=SC1090
[[ -f "$scripts/setup.sh" ]] && source "$scripts/setup.sh"

pushd "$(dirname "$0")/.." > /dev/null
root=$(pwd -P)
popd > /dev/null

ins="$root/documents"
outs="$root/out"
scripts="$root/documents/userguide/scripts"

hash asciidoctor >/dev/null 2>&1 || gem install asciidoctor
hash asciidoctor-pdf >/dev/null 2>&1 || gem install --pre asciidoctor-pdf

# shellcheck disable=SC1090
source "$root/ci/vars.sh"

function doit {
    indir=$1
    outdir=$2

    aaa=$(dirname "$indir/index.txt")
    bbb=$(basename "$aaa")
    echo "Processing: $bbb/index.txt"

    # insert build date
    dat=`date "+%Y-%m-%d"`
    dattim=`date "+%Y-%m-%d %H:%M:%S %Z"`
    sed "s/__DATE__/$dat/g" "$indir/index.txt" > "$indir/index.txt.2"

    # txt -> html
    asciidoctor -o "$outdir/index.html" "$indir/index.txt.2"  &> errs.tmp
    if [[ -s errs.tmp ]] ; then
        cat errs.tmp
        exit 1
    fi

    # txt -> pdf
    asciidoctor -r asciidoctor-pdf -b pdf -o "$outdir/index.pdf" "$indir/index.txt.2"  &> errs.tmp
    if [[ -s errs.tmp ]] ; then
        cat errs.tmp
        exit 1
    fi

    # if errs.tmp is empty, remove it
    [[ -s "errs.tmp" ]] || rm "errs.tmp"

    # copy images directory to out dir
    cp -R "$indir/images" "$outdir"

    # copy scripts directory to out dir
    cp -R "$indir/scripts" "$outdir"
}

function run_tests {
    # verify the example scripts
    echo
    echo "Testing started"

    cp "$scripts/terrametrics.tif" "$root"

    echo ; echo ; echo TEST START ; echo ; echo
    pushd $scripts
    ./runall.sh
    popd
    echo ; echo ; echo TEST END ; echo ; echo

    rm -f "$root/terrametrics.tif"

    echo "Testing completed"
}

[[ -d "$outs" ]] && rm -rf "$outs"

mkdir "$outs"

doit "$ins" "$outs"
doit "$ins/userguide"   "$outs/userguide"
doit "$ins/devguide"    "$outs/devguide"

mkdir "$outs/presentations"
# shellcheck disable=SC2086
cp -f $ins/presentations/*.pdf "$outs/presentations/"

# Can't run the tests because we don't have an API key.
#run_tests

echo Done.

tar -czf "$APP.$EXT" -C "$root" out
