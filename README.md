# API generated AWS billing report

The is a small, Ruby-based application which generates
the current billing from AWS for a particular account.
The API call returns JSON, which needs to be parsed
and filtered, with only the non-zero billing amounts
reported. The initial report is markdown, and possibly
a terminal-friendly output.


