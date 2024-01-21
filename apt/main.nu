# Create a .deb file containing the nushell binaries and return a string with the path to the archive
export def main [
    version: string, # the version of nushell to create a .deb file for
] {
    let tmpdir     = mktemp -d
    let name       = $"nu-($version)-x86_64-linux-gnu-full"
    let dir_base   = $"($tmpdir)/($name)"
    let dir_debian = $"($dir_base)/DEBIAN"
    let dir_bins   = $"($dir_base)/usr/local/bin"
    let url        = $"https://github.com/nushell/nushell/releases/download/($version)/($name).tar.gz"
    let year       = date now | date to-record | get year

    print $"Creating directory ($dir_bins)"
    if not ($dir_bins | path exists) {
        mkdir $dir_bins
    }
    print $"Creating directory ($dir_debian)"
    if not ($dir_debian | path exists) {
        mkdir $dir_debian
    }

    print "Rendering templates"
    render_templates --dir $dir_debian --version $version --year $year

    print "downloading"
    let tmpdir = mktemp -d
    let downloaded_archive = download --path $tmpdir $url

    print "extracting"
    extract --archive $downloaded_archive --tmpdir $tmpdir

    print "moving files"
    mv $"($tmpdir)/($name)/*" $dir_bins

    print "cleaning up downloaded archive"
    rm -rf $tmpdir

    print $"building debian package ($name).deb"
    ^dpkg-deb --build $dir_base

    print "validating output"
    ^dpkg-deb --info $"($dir_base).deb"
    ^dpkg-deb --contents $"($dir_base).deb"

    print "cleaning up build files"
    rm --permanent --recursive $dir_base

    print "debian packaging complete"
    return $"($dir_base).deb"
}

def extract [--archive: string, --tmpdir: string]: nothing -> nothing {
    ^tar xzf $archive -C $tmpdir
}

# Downloads a file and returns the path where the file was downloaded
def download [url: string, --path: path] {
    # Use the URL to create a filepath to save the downloaded file to
    let filename = $url | split row "/" | last
    let outpath = $path | path join $filename

    http get --max-time 3600 $url | save $outpath

    return $outpath
}

# Render_templates opens the template files and replaces the %YEAR% and %VERSION% strings and saves them
def render_templates [--dir: string, --version: string, --year: int] {

    let chglog = open $"($env.FILE_PWD)/templates/DEBIAN/changelog"
    let control = open $"($env.FILE_PWD)/templates/DEBIAN/control"
    let copyright = open $"($env.FILE_PWD)/templates/DEBIAN/copyright"

    $chglog | str replace "%VERSION%" $version | save -f ($dir | path join "changelog")
    $control | str replace "%VERSION%" $version | save -f ($dir | path join "control")
    $copyright | str replace "%YEAR%" $"($year)" | save -f ($dir | path join "copyright")

    cp $"($env.FILE_PWD)/templates/DEBIAN/postinst" ($dir | path join "postinst")
    cp $"($env.FILE_PWD)/templates/DEBIAN/postrm" ($dir | path join "postrm")

    # Ensure the files have the appropriate permissions
    chmod 0755 ($dir | path join "postinst")
    chmod 0755 ($dir | path join "postrm")
}
