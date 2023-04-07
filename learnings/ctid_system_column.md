# System column ctid as row identifier
* In Oracle we have system column ROWID which something like “address of the row id Oracle datafile”. This ROWID is unique because beside of table and row signature it contains also signature of datafile. Oracle stores everything in big datafiles and have only one database with separate schemas.

* PostgreSQL also have such “row address”. It is called CTID and every row has it. Difference against Oracle is that CTID is unique only inside particular table. Because PostgreSQL have separate databases on one server and stores every table in separate file on the disk.

* CTID is defined very simply as “address of the row inside data file” and if you select it you will see results like “(0,1)”, “(0,2)” with datatype TID. This datatype you can easily cast as TEXT or as POINT.

* First number means page serial number and second number is row serial number inside page. Page is 8KB big block of data from data file. PostgreSQL always creates whole pages. Therefore even if you have only small table with a few rows of data the smallest size of the data file is always 8KB.

* Be aware that this CTID cannot be use to identify in which order database really stored rows. Because PostgreSQL tries to use pages as efficiently as possible therefore if it found enough space on old pages for inserted row it will place is there. So for example after creating row with CTID= (10,1) it can create the other row with CTID= (0,268) simply because there was a space left in first page.

* If row is updated than old row is deleted and new created. So if newly inserted row had CTID= (0,10) then updated row will have other CTID because it was written to other place.