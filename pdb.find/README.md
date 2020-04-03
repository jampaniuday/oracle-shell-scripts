The concept behind my findPDB script is to simplify the search for a pluggable database (PDB) across several container databases (CDB). This script serves the most value in environments containing alot of CDB. I do not see the point of using this script in a single CDB shop where all your PDB's will be housed in that single CDB. You can run this script remotely: you don't have to run the script locally from each CDB host. 
> Note, this script is written in bash and is case sensitive (so enter the correct casing of your desired PDB).
> Note, this script expects ORACLE_SID and ORACLE_HOME set in bash_profile

## Files
- **findPDB.sh**<br/>
"getPDB.sh" is the actual script containing the search logic. 

- **targets**<br/>
The "targets" file contains the list of CDB's that you want to search and is used by the getPDB.sh script. A space, ' ', is used as the field terminator. A new line terminates the entry. Lines beginning with a pound sign, "#" are comments or disabled entries.</p>
Entries are of the form:<br/>
`CDB HOSTNAME` `CDB SID` `CDB SYSTEM PASSWORD`

### Usage
<p>1. Modify the "targets" file to list your CDB connection details<br/>
2. Execute getPDB.sh from the linux terminal, passing the desired PDB name as an argument</p>

<p>The script will only display a message once a match is found. In the example below I'm using the getPDB script to search for a PDB called testpdb.</p>

```./findPDB.sh {pdb name}```
