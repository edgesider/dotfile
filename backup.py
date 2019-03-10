#! /usr/bin/env python3
'''
A script to manage backup of dotfile.
Usage:
    1. Run `./backup.py genempty` to generate a empty backup_list file. Then
    add the files need to be backuped to it.
    2. Run `./backup.py backup` to backup.
    3. Run `./backup.py restore` to restore. restore action will attemp to
    restore permission bits, ownner, group and other metainfo, so it may
    require root permission.
    4. Run `./backup.py clean` will delete all backuped files, include its metainfo.

    More options please check help text.
'''

import argparse
import pwd
import os
import json
import shutil
import sys
from collections import namedtuple

'''
backup backup -m 777 -u kai -g kai -l backup.list -i metainfo -d dir
backup restore -i metainfo

File Format:
`backup.list`. List of files will to be backuped.
[
    ['src_file_path', ''],
    ['src_file_path', 'empty_or_alias']
]

`metainfo`. Metainfo file written by `backup` action, which store files' stat and location info.
{
    "files": [
        {
            "dst": "backuped file",
            "src": "file source",
            "src_is_dir": true,
            "src_dir_stat": [
                {
                    "name": "filename",
                    "mode": 744,
                    "own": "kai",
                    "grp": "kai"
                },
                {
                    "name": "filename",
                    "mode": 744,
                    "own": "kai",
                    "grp": "kai"
                }
            ],
            "src_expanded": "file expanded"
            "src_mode": 744,
            "src_own": "kai",
            "src_grp": "kai"
        }
    ]
}
'''

Metainfo = namedtuple('Metainfo', ('dst', 'src', 'src_expanded', 'src_is_dir', 'src_dir_stat', 'src_mode', 'src_own', 'src_grp'))
Filestat = namedtuple('Filestat', ('name', 'mode', 'own', 'grp'))

def read_backup_list(filepath):
    '''Read backup list'''
    with open(filepath) as f:
        return json.load(f)

def read_metainfo(filepath):
    '''Read metainfo file of backuped files'''
    with open(filepath) as f:
        d = json.load(f)
        metalist = [Metainfo(**meta) for meta in d['files']]
    rv = []
    for meta in metalist:
        if meta.src_is_dir:
            subfiles_stat = [Filestat(**stat) for stat in meta.src_dir_stat]
            # _replace() function will generate and return a new namedtulpe object, so we should build a new list.
            rv.append(meta._replace(src_dir_stat=subfiles_stat))
        elif meta.src_dir_stat is not None:
            rv.append(meta._replace(src_dir_stat=None))
        else:
            rv.append(meta)
    return rv

def meta_to_dict(metainfo: Metainfo):
    rv = metainfo._asdict()
    if rv['src_dir_stat']:
        rv['src_dir_stat'] = [submeta._asdict() for submeta in rv['src_dir_stat']]
    return rv

def write_metainfo(metalist, outfile):
    '''Rrite metainfo file of `metalist` to `outfile`'''
    metalist = [meta_to_dict(meta) for meta in metalist]
    with open(outfile, 'w') as f:
        json.dump({'files': metalist}, f, indent=4, ensure_ascii=False)

def remove_dir_file(dirorfile):
    '''Remove dir or file'''
    if os.path.isdir(dirorfile):
        # os.removedirs(dirorfile)
        shutil.rmtree(dirorfile)
    else:
        os.remove(dirorfile)

def rename_dst(dst_path):
    '''Rename file to show hidden file'''
    if dst_path.startswith('.'):
        dst_path = '_' + dst_path.lstrip('.')
    return dst_path

def mkdir(dirpath):
    '''mkdir recursively'''
    dirpath = os.path.abspath(dirpath)
    tomake = [dirpath]
    while True:
        dirpath = os.path.dirname(dirpath)
        if os.path.exists(dirpath):
            break
        else:
            tomake.insert(0, dirpath)
    for d in tomake:
        os.mkdir(d)

def ensure_dir(filepath):
    dirpath = os.path.dirname(filepath)
    if not os.path.exists(dirpath):
        mkdir(dirpath)

def check_confirm(input_text, default):
    input_text = input_text.strip()
    if input_text == '':
        return default
    if input_text.lower() == 'y':
        return True
    if input_text.lower() == 'n':
        return False
    return False

def get_filestat(filepath):
    stat = os.stat(filepath)
    mode = stat.st_mode
    own = pwd.getpwuid(stat.st_uid).pw_name
    grp = pwd.getpwuid(stat.st_gid).pw_name
    return Filestat(name=filepath, mode=mode, own=own, grp=grp)

def get_dir_filestats(dirpath):
    files = []
    for lay in os.walk(dirpath):
        files.extend([os.path.join(lay[0], sub) for sub in lay[1] + lay[2]])
    return [get_filestat(f) for f in files]

def backup_from_meta(meta: Metainfo):
    '''Backup one file specified by meta'''
    assert os.path.exists(meta.src_expanded)

    if os.path.exists(meta.dst):
        remove_dir_file(meta.dst)
    if os.path.isdir(meta.src_expanded):
        shutil.copytree(meta.src_expanded, meta.dst, symlinks=True)
    else:
        ensure_dir(meta.dst)
        shutil.copy(meta.src_expanded, meta.dst, follow_symlinks=False)

    # TODO 加入权限设置
    print("Sucessfully backup {} to {}".format(meta.src_expanded, meta.dst))

def backup_action(filepath, user=None, group=None, mode='744', metainfo='metainfo', outdir='.'):
    '''Backup action'''
    metalist = []

    filelist = read_backup_list(filepath)

    if not os.path.exists(outdir):
        mkdir(outdir)
    for src_name, user_dst in filelist:
        src_abs = os.path.expanduser(src_name)
        src_abs = os.path.abspath(src_abs)
        src_abs = os.path.realpath(src_abs)
        assert os.path.exists(src_abs)

        stat = os.stat(src_abs)
        mode = stat.st_mode
        own = pwd.getpwuid(stat.st_uid).pw_name
        grp = pwd.getpwuid(stat.st_gid).pw_name

        dst = None
        if not user_dst:
            # user did not give a dst path
            # realpath() remove slash suffix of directory name and keep file name unchanged
            dst = os.path.basename(src_abs)
            dst = rename_dst(dst)
        else:
            # user did give a dst path
            if os.path.basename(user_dst) == '':
                # user give a directory
                base_name = os.path.basename(src_abs)
                base_name = rename_dst(base_name)
                dst = os.path.join(user_dst, base_name)
            else:
                # user give a filepath
                dst = user_dst
        dst = os.path.join(outdir, dst)

        src_is_dir = os.path.isdir(src_abs)
        src_dir_stat = None
        if src_is_dir:
            src_dir_stat = get_dir_filestats(src_abs)

        meta = Metainfo(src=src_name, src_expanded=src_abs, dst=dst,
                src_is_dir=src_is_dir, src_dir_stat=src_dir_stat,
                src_mode=stat.st_mode, src_own=own, src_grp=grp)

        backup_from_meta(meta)
        metalist.append(meta)

    write_metainfo(metalist, 'metainfo')

def chown_dir(dirmeta):
    for sub in dirmeta.src_dir_stat:
        shutil.chown(sub.name, sub.own, sub.grp)
        os.chmod(sub.name, sub.mode)

__confirm_all__ = False
def restore_from_meta(meta: Metainfo, confirm=True):
    global __confirm_all__

    if not os.path.exists(meta.dst):
        print("file '{}' not found".format(meta.dst))

    if os.path.exists(meta.src_expanded):
        if not __confirm_all__ and confirm:
            info = "{} existed. Overwrite? [Y/n/a]".format(meta.src_expanded)
            cfm = input(info).strip()
            if cfm == 'a':
                __confirm_all__ = True
            elif not check_confirm(cfm, True):
                print("{} skipped.".format(meta.src_expanded))
                return
        remove_dir_file(meta.src_expanded)

    if os.path.isdir(meta.dst):
        shutil.copytree(meta.dst, meta.src_expanded, symlinks=True)
        chown_dir(meta)
    else:
        dir = os.path.split(meta.src_expanded)[0]
        if not os.path.exists(dir):
            mkdir(dir)
        shutil.copy(meta.dst, meta.src_expanded, follow_symlinks=False)

    # TODO chown/chmod recursively
    shutil.chown(meta.src_expanded, meta.src_own, meta.src_grp)
    os.chmod(meta.src_expanded, meta.src_mode)
    print('Restored ' + meta.src_expanded)

def restore_action(metafile):
    '''Restore action'''
    # TODO restore subfiles
    __confirm_all__ = False

    metalist = read_metainfo(metafile)
    print('Please check:')
    for i, meta in enumerate(metalist):
        flag = None
        if not os.path.exists(meta.dst):
            flag = 'x'
        elif os.path.isdir(meta.dst):
            flag = 'd'
        else:
            flag = 'f'
        print('[{}][{}] {}'.format(i, flag, meta.src_expanded))
    if not check_confirm(input('These files will be restored. Continue? [y/N]'), False):
        return
    for meta in metalist:
        restore_from_meta(meta)

def clean_action(metafile):
    '''Clean action. delete backuped files specified by metalist'''
    metalist = read_metainfo(metafile)
    for meta in metalist:
        try:
            remove_dir_file(meta.dst)
        except FileNotFoundError as e:
            print('{} not found.'.format(meta.dst))
    os.remove(metafile)

def generate_backup_list_file(filepath):
    with open(filepath, 'w') as f:
        content = '[\n' +\
                '["src_path1", "alias1"],\n' +\
                '["src_path2", "alias2"]\n' +\
                ']\n'
        f.write(content)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("action", help='backup/clean/restore/genempty')
    parser.add_argument("-l", "--backuplist", dest='backuplist', default='backup.list', help='list file of backup files')
    parser.add_argument("-i", "--out-metainfo", dest='metainfo', default='metainfo', help='metainfo to write')
    parser.add_argument("-d", "--out-dir", dest='out_dir', default='out', help='dir of backup files')
    args = parser.parse_args()

    if args.action == 'backup':
        backup_action(args.backuplist, metainfo=args.metainfo, outdir=args.out_dir)
    elif args.action == 'clean':
        clean_action(args.metainfo)
    elif args.action == 'restore':
        restore_action(args.metainfo)
    elif args.action == 'genempty':
        generate_backup_list_file('backup.list')
    else:
        parser.print_help()
        sys.exit(1)
