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

def check_confirm(input_text, default):
    input_text = input_text.strip()
    if input_text == '':
        return default
    if input_text.lower() == 'y':
        return True
    if input_text.lower() == 'n':
        return False
    return False

def backup_from_meta(meta: Metainfo):
    '''Backup one file specified by meta'''
    if os.path.exists(meta.dst):
        remove_dir_file(meta.dst)
    if os.path.isdir(meta.src_expanded):
        shutil.copytree(meta.src_expanded, meta.dst)
    else:
        shutil.copy(meta.src_expanded, meta.dst)

    # TODO 加入权限设置
    # print("Sucessfully backup {} to {}".format(meta.src_expanded, meta.dst))

def backup_action(filepath, user=None, group=None, mode='744', metainfo='metainfo', outdir='.'):
    '''Backup action'''
    metalist = []

    filelist = read_backup_list(filepath)

    if not os.path.exists(outdir):
        os.mkdir(outdir)
    for src_name, dst_path in filelist:
        expanded = os.path.abspath(os.path.expanduser(src_name))
        stat = os.stat(expanded)
        own = pwd.getpwuid(stat.st_uid).pw_name
        grp = pwd.getpwuid(stat.st_gid).pw_name
        # realpath去掉目录末尾的斜杠
        if not dst_path:
            dst = os.path.split(os.path.realpath(expanded))[1]
            dst = rename_dst(dst)
        else:
            dst = dst_path
        dst = os.path.join(outdir, dst)
        meta = Metainfo(src=src_name, src_expanded=expanded, dst=dst,
                src_mode=stat.st_mode, src_own=own, src_grp=grp)

        backup_from_meta(meta)
        metalist.append(meta)

    write_metainfo(metalist, 'metainfo')

__confirm_all__ = False
def restore_from_meta(meta: Metainfo, confirm=True):
    global __confirm_all__
    if os.path.exists(meta.src_expanded):
        if not __confirm_all__ and confirm:
            info = "{} existed. Overwrite? [Y/n/a]".format(meta.src_expanded)
            cfm = input(info).strip()
            if cfm == 'a':
                __confirm_all__ = True
                return
            if not check_confirm(cfm, True):
                print("{} skipped.".format(meta.src_expanded))
                return
        remove_dir_file(meta.src_expanded)

    if not os.path.exists(meta.dst):
        raise FileNotFoundError(meta.dst)

    if os.path.isdir(meta.dst):
        shutil.copytree(meta.dst, meta.src_expanded)
    else:
        dir = os.path.split(meta.src_expanded)[0]
        if not os.path.exists(dir):
            os.mkdir(dir)
        shutil.copy(meta.dst, meta.src_expanded)

    # TODO chown/chmod recursively
    shutil.chown(meta.src_expanded, meta.src_own, meta.src_grp)
    os.chmod(meta.src_expanded, meta.src_mode)

def restore_action(metafile):
    '''Restore action'''
    # TODO show check info before restore
    metalist = read_metainfo(metafile)
    print('Please check:')
    for i, meta in enumerate(metalist):
        dir_flag = 'd' if os.path.isdir(meta.src_expanded) else 'f'
        print('[{}][{}] {}'.format(i, dir_flag, meta.src_expanded))
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
