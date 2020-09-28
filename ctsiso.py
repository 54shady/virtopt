#!/usr/bin/env python
# coding=utf-8

import argparse
import os
import textwrap
from subprocess import Popen, PIPE


def run_command(cmd, stdin=None, stdout=PIPE, stderr=None):
    try:
        p = Popen(cmd, shell=True,
                  stdout=stdout, stdin=stdin, stderr=stderr,
                  executable="/bin/bash")
        out, err = p.communicate()
        return out
    except KeyboardInterrupt:
        print('Stop')


def main():
    '''
    python3 ctsiso.py -w /path/to/ws -o /path/to/output.iso -i /iso/mount/point -l /path/to/Package
    '''
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent(''' centos arm ISO '''))

    parser.add_argument("-w", "--workspace", help="workspace", type=str,
                        required=True)
    parser.add_argument("-i", "--iso", help="iso image mount dir", type=str)
    parser.add_argument("-o", "--output", help="output path", type=str)
    parser.add_argument("-l", "--local", help="local overlay package", type=str)
    parser.add_argument("-c", "--cachep", help="add cache package", type=str)

    # parse the args
    args = parser.parse_args()
    ws = args.workspace

    # workspace not ready
    if not os.path.exists(ws):
        os.mkdir(ws)
        run_command("rsync -av --exclude=Packages/* %s/ %s" % (args.iso, ws))

    # add cache package
    if args.cachep:
        cachepkg = "/var/cache/yum/aarch64/7/base/packages"
        if os.path.exists(cachepkg):
            run_command("cp -rvf %s/* %s/Packages/" % (cachepkg, ws))

    # using local overlay package
    if args.local:
        run_command("cp -rvf %s/* %s/Packages/" % (args.local, ws))

    # custom the ISO
    run_command("cp armgrub.cfg %s/EFI/BOOT/grub.cfg" % ws)
    run_command("cp ks.cfg %s/" % ws)

    # rebuid the metafile
    run_command("rm -rvf %s/repodata/*-comps.xml" % ws)
    run_command("cp comps.xml %s/repodata/" % ws)
    cmd = "createrepo -g %s/repodata/comps.xml %s" % (ws, ws)
    run_command(cmd)

    # pack ISO
    efiboot = "images/efiboot.img"
    bootcata = "boot.catalog"
    volume = "myctos"
    outiso = args.output if args.output else "/tmp/myctos.iso"
    cmd = '''rm -rvf %s && cd %s && genisoimage -e %s -no-emul-boot -T -J -R -c %s -hide %s -V "%s" -o %s .''' % (
        outiso, ws, efiboot, bootcata, bootcata, volume, outiso)
    run_command(cmd)


if __name__ == '__main__':
    main()
