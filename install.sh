#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${__dir}" || exit 1

# install mm
sudo cp mm /usr/local/bin/mm
sudo chmod +x /usr/local/bin/mm

# install mmuild
sudo cp mmbuild /usr/local/bin/mmbuild
sudo chmod +x /usr/local/bin/mmbuild
