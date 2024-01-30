#!/usr/bin/env python3
""" Get the source url and checksum corresponding to the package and
    version supplied in SPEC_FILE"""
import os
import sys

from pypi_simple import PyPISimple

if len(sys.argv) < 2:
    print(f"Usage: {os.path.basename(sys.argv[0])} SPEC_FILE")
    sys.exit(1)


SPEC_FILE = sys.argv[1]


def print_source_url(name, version):
    """Get the source url and checksum corresponding to the package and version supplied"""
    package = {
        "name": name,
        "url": "",
        "checksum": "",
    }
    with PyPISimple() as client:
        requests_page = client.get_project_page(name, timeout=10.0)
    for request in requests_page.packages:
        if (
            request.project.lower() == name.lower()
            and request.version == version
            and request.package_type == "sdist"
        ):
            package["url"] = request.url
            package["checksum"] = request.digests["sha256"]
            break
    if package["url"] == "" or package["checksum"] == "":
        print(
            f"Could not find source url and/or checksum for package {name} version {version}",
            file=sys.stderr,
        )
        sys.exit(1)
    print(
        f'  resource "{name}" do\n'
        f"    url \"{package['url']}\"\n"
        f"    sha256 \"{package['checksum']}\"\n"
        f"  end"
    )


def process_packages():
    """Process the packages in ${WORK_DIR}/poetry.packages.new"""
    package = {}
    with open(SPEC_FILE, "r", encoding="latin-1") as f:
        recs = f.readlines()
    for rec in recs:
        field = rec.split()
        package[field[0]] = field[1]
    for key, value in sorted(package.items()):
        print_source_url(key, value)


def main():
    """Main entry point"""
    process_packages()
    # print(get_source_url("macos-tags", "1.5.1"))


if __name__ == "__main__":
    main()
