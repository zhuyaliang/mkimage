#! /usr/bin/python3

import sys
import os
import xml.etree.ElementTree as ET
import urllib.request
import gzip

MAINLINE_BASEURL='http://119.3.219.20:8080/Mainline/standard_aarch64/'
EXTRAS_BASEURL='http://119.3.219.20:8080/Extras/standard_aarch64/'

def get_repomd_url(repo_type):
    response = urllib.request.urlopen(repo_type + 'repodata/repomd.xml')
    html = response.read()
    root = ET.fromstring(html.decode('utf-8'))
    for data in root.findall('{http://linux.duke.edu/metadata/repo}data'):
        if (data.get('type') == 'primary'):
            repo_location = data.find('{http://linux.duke.edu/metadata/repo}location')
            return repo_type + repo_location.get('href')

def dl_file(f_url, dl_dir):
    response = urllib.request.urlopen(f_url)
    f_name = f_url.split('/')[-1]
    if not os.path.exists(dl_dir):
        os.makedirs(dl_dir)
    f = open(dl_dir + '/' + f_name, 'wb')
    f.write(response.read())
    f.close()

def get_rpm_url(repo_type, pkg_list_file, dl_dir):
    repomd_url = get_repomd_url(repo_type)
    response = urllib.request.urlopen(repomd_url)
    ziphtml = response.read()
    html = gzip.decompress(ziphtml)
    root = ET.fromstring(html.decode('utf-8'))
    for package in root.findall('{http://linux.duke.edu/metadata/common}package'):
        name = package.find('{http://linux.duke.edu/metadata/common}name')
        with open(pkg_list_file, 'r') as filelist:
            for rpm_name in filelist.readlines():
                if (name.text == rpm_name.strip()):
                    if (('aarch64' == package.find('{http://linux.duke.edu/metadata/common}arch').text) or ('noarch' == package.find('{http://linux.duke.edu/metadata/common}arch').text)):
                        location = package.find('{http://linux.duke.edu/metadata/common}location')
                        dl_file(repo_type + location.get('href'), dl_dir)
                        break

get_rpm_url(MAINLINE_BASEURL, sys.argv[1], sys.argv[2])
get_rpm_url(EXTRAS_BASEURL, sys.argv[1], sys.argv[2])
