# Components
Repository for Bottles components

## Why a centralized repository?
With a centralized repository we can provide some data such as the checksum, which is useful for validate downloads.

## How to contribute
To propose new components, it is necessary to open a [Pull Request](https://github.com/bottlesdevs/components/pulls) with the manifest of the component we want to add, here are some examples of manifest:
- [dxvk-1.9](https://github.com/bottlesdevs/components/blob/main/dxvk/dxvk-1.9.json)
- [Proton-5.21-GE-1](https://github.com/bottlesdevs/components/blob/main/runners/proton/Proton-5.21-GE-1.json)
- [chardonnay-6.11](https://github.com/bottlesdevs/components/blob/main/runners/wine/chardonnay-6.11.json)

### Manifest layout
Each poster must follow the following layout:
```json
{
  "Name": "chardonnay-6.11",
  "Provider": "bottles",
  "Channel": "stable",
  "File": [
    {
      "file_name": "chardonnay-6.11-x86_64.tar.gz",
      "url": "https://github.com/bottlesdevs/wine/releases/download/6.11/chardonnay-6.11-x86_64.tar.gz",
      "file_checksum": "da48f5bd2953a0ce8b5972008df8fafc",
      "rename": "chardonnay-6.11-x86_64.tar.gz"
    }
  ]
}
```

where:
- **Name** is a name without spaces, including version, of the component (must reflect the name of the manifest file)
- **Provider** is the name of the component supplier (not the maintainer)
- **Channel** should be stable or unstable
- **File** is where it is stated how to get the component archive
  - **file_name** is the full name of the component archive
  - **url** is the direct URL to the archive download (ornly tarball are supported)
  - **file_checksum** is the MD5 checksum of the archive
  - **rename** this field must be the same as the name of the component (plus the extension), it is needed if the archive has a name but acquires another when it is extracted

### Guidelines
The sources of the components must be public and searchable and must not infringe any copyright. Also, each archive must contain the compiled version and not the source code.


## Currently offered runners
We offer several runners in Bottles:
- `chardonnay` (our runner, available by default in Bottles v3)
- `lutris`
- `proton-ge`
