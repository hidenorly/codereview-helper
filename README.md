# codereview-helper

This is code review helper for modified files.
This is expected to execute before ```git commit```
This helper enumerates ```git add``` files or all of modified files if ```-a``` specified, and to execute executable static code analysis and llm-review which is enabled by gpt which requires API key, etc.

```
$ ruby check-modified-files.rb --help
Usage: execute this in the git folder's root
    -a, --all                        Specify if you want to apply all modified files
    -c, --cppcheck=                  Specify option for cppcheck (default:) e.g. --enable=all
        --inferCapture=
                                     Specify option for infer on the capture command (default:)
        --inferAnalyze=
                                     Specify option for infer on the analyze command (default:)
```
