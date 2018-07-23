# Android-Crack-CLI

Android crack tool for Unix-like system commend line interface.

# Usage

use `crack.sh -h` to check the usage:

```
Usage:
crack.sh [OPTIONS] [ARGS...] [TARGET]
```

Option|Args|Desc
-|-|-
-o|OUTPUT_DIR|specify dir to store decompiled file, 'SCRIPTS_DIR/outputs' will be used if not specified.
-f||force to re-decompile target file. Cached result will be presented if this option is not used, if there is any.
-e|EXEC|run '$exec RESULT_DIR' after decompiling finished. You can use tools like VSCode or Atom to view the result.

TARGET could be one of below:

    apk, aar, jar, dex, directory

If target file has other ext names or has no ext name, then it will be treated as an apk file. 

If target is directory, then it will recursively process all files with accepted ext name, and ignore files which have no ext name.

# License
        Copyright 2018 DrkCore

        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

            http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.