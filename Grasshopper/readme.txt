Troubleshooting Common Issues:

Symptom	                            Cause	                            Solution
format string expected              Maple printf with single quotes	    Use double quotes: printf("VALUE=%a\n", ...)
string expected for string format   Using %s with non-string values	    Use %a for numbers/units, %s only for strings
reserved word \if` unexpected`	    Missing statement terminator	    Add : or ; after every Maple statement
undefined name 'Grasshopper'	    GH1 doesn't auto-inject	            Add import Grasshopper at top
GH_Path not found	                Wrong namespace	                    Use Grasshopper.Kernel.Data.GH_Path in GH1
Tree outputs <null>	                Port name mismatch	                Ensure variable name = output port name