# PostgreSQL versions

* I started to work with PostgreSQL in 2013 with version 8.4 although the latest version in those days was 9.3
* And I worked will all subsequential versions - all the way through 9.4, 9.5, 9.6, 10, 11, 12, 13, 14, 15 - which is the latest version currently (04/2023)
* From my perspective version 10 was big change in the overall philosophy so here are descriptions of major changes in PostgreSQL starting from version 10.
  * It also shows that AI tools still do not have current data

---

ChatSonic GPT-4:

1. PostgreSQL 10:

   - Logical replication using publish/subscribe: This feature allows data to be replicated selectively between databases, providing more flexibility for replication [1].
   - Declarative table partitioning: This simplifies the process of partitioning tables, making it easier to manage large tables and improve query performance [2].
   - Improved query parallelism: This enhancement allows for faster execution of complex queries by distributing the workload across multiple CPU cores [2].
   - Renaming pg_xlog to pg_wal and pg_clog to pg_xact: These directory changes improve clarity and avoid confusion with transaction logs [1].
   - Other features: Native partitioning, faster analytics queries, improved security, and performance improvements [3].
   - Improved performance: General performance improvements, including better index scans and hash joins [1].
2. PostgreSQL 11:

   - Partitioning improvements: Enhanced support for partition pruning and faster partitioning operations [4].
   - Just-in-time (JIT) compilation: This feature uses the LLVM compiler to improve the execution of complex SQL queries [4].
   - Stored procedures with transaction control: This allows users to create stored procedures with the ability to control transactions [4].
   - Enhanced parallelism: Further improvements to parallel query execution, including support for parallelized data definition commands [4].
   - Other features: Improved performance for large objects, better monitoring and diagnostics, and SQL conformance enhancements [4].
   - More efficient storage: Improvements to storage efficiency, including space savings for null values and better compression for large objects [2].
3. PostgreSQL 12:

   - Improved query performance: Significant enhancements to partition pruning and better query execution plans [5].
   - Indexes on partitioned tables: This feature enables users to create indexes on partitioned tables without having to create them on each partition separately [5].
   - Just-in-time (JIT) compilation improvements: Further enhancements to the JIT feature, improving the execution of complex SQL queries [5].
   - Other features: SQL conformance enhancements, pluggable storage, and improved monitoring and diagnostics [5].
   - B-tree improvements: Improvements to the B-tree index type, including faster range queries and improved index-only scans [3].

   * Generated columns: This feature allows for the creation of columns derived from other columns, simplifying data management and improving query performance [3].
   * Improved security: Enhancements to security, including stronger password hashing and improved SSL/TLS support [3].
4. PostgreSQL 13:

   - Parallel vacuum: This feature allows vacuuming to be performed in parallel, improving the efficiency of large-scale database maintenance operations [6].
   - Incremental sorting: This enhancement provides faster sorting of large datasets by reusing previously sorted data [6].
   - Improved partitioning: Further enhancements to partition pruning and query performance [6].
   - Other features: Security improvements, more efficient B-tree indexes, and better monitoring and diagnostics [6].
   - Improved indexing: Enhancements to indexing, including faster hash indexes and more efficient vacuuming of B-tree indexes [4].

   * General performance improvements: Improvements to query execution and transaction throughput [4].
   * Better monitoring: Enhancements to monitoring and diagnostic tools, including better tracking of query performance [4].

Please note that these are the major features and improvements for each release, and there are many more minor features and bug fixes included in each version as well.

References:
[4] https://www.postgresql.org/about/news/1894/
[5] https://www.postgresql.org/about/news/1976/
[6] https://www.postgresql.org/about/news/2077/

`<b>`References:`</b>`
`<span>`[1] `<a href='https://www.postgresql.org/docs/release/10.0/' target='_blank' class='text-purple-1 underline'>`PostgreSQL: Release Notes`</a>`
`<span>`[2] `<a href='https://www.postgresql.org/about/news/postgresql-10-released-1786/' target='_blank' class='text-purple-1 underline'>`PostgreSQL 10 Released`</a>`
`<span>`[3] `<a href='https://wiki.postgresql.org/wiki/New_in_postgres_10' target='_blank' class='text-purple-1 underline'>`New in postgres 10`</a>`

---

ChatGPT-4:


Here's a summary of the major PostgreSQL versions starting from version 10, along with their important changes and features:

1. PostgreSQL 10 (released on October 5, 2017):
   * Logical Replication: Allows selective replication of data between different PostgreSQL instances, which is useful for load balancing and scaling.
   * Declarative Table Partitioning: Simplifies the creation and maintenance of partitioned tables, improving query performance.
   * Improved Query Parallelism: Enhancements in parallel query execution for better utilization of system resources and faster query processing.
   * SCRAM Authentication: Provides a more secure method of password-based authentication using the Salted Challenge Response Authentication Mechanism (SCRAM-SHA-256).
   * Quorum Commit for Synchronous Replication: Enables configuring synchronous replication to require confirmation from multiple standby servers, improving fault tolerance.
2. PostgreSQL 11 (released on October 18, 2018):
   * Improved Partitioning: Enhancements in table partitioning, including support for hash partitioning, primary and foreign keys on partitioned tables, and improved query performance.
   * Parallel B-tree Index Builds: Allows parallel index creation, reducing the time taken to create large indexes.
   * Just-In-Time (JIT) Compilation: Supports JIT compilation for accelerating the execution of complex queries by compiling specific parts of the query plan.
   * Stored Procedures: Adds support for stored procedures with transaction control, allowing complex server-side logic to be encapsulated in reusable procedures.
3. PostgreSQL 12 (released on October 3, 2019):
   * Improved Partitioning Performance: Further enhancements in partition pruning and faster partition creation, leading to better query performance on partitioned tables.
   * Improved Indexing Performance: Introduction of "Most Common Value" statistics for B-tree indexes, which improves the planner's ability to optimize queries.
   * Generated Columns: Adds support for generated columns that compute their values based on the content of other columns in the same table.
   * SQL/JSON Path Language: Support for querying JSON data using the SQL/JSON Path Language, a standardized way to query and manipulate JSON data.
4. PostgreSQL 13 (released on September 24, 2020):
   * Parallel Vacuuming: Enables parallel processing for vacuuming B-tree indexes, which improves the maintenance and recovery performance of large tables.
   * Incremental Sorting: Improves query performance by sorting only the required data when the query plan includes multiple sort operations.
   * Improved Space Management for B-tree Indexes: Reduces index size and improves performance by more efficiently reusing and compacting space within the index.
   * Extended Monitoring Capabilities: Adds new monitoring tools and views for easier diagnosis of performance issues, like the `pg_stat_progress_analyze` view and `pg_stat_database` improvements.
5. PostgreSQL 14 (released on September 30, 2021):
   * Improved Connection Scalability: Reduces the overhead of managing a large number of connections using the "backend_flush_after" parameter and other enhancements.
   * Vacuuming Improvements: Further enhancements in vacuuming, such as "bottom-up" index deletion and improved parallelism.
   * Expanding Continuous Aggregates: Allows updating continuous aggregates to include newly ingested data more efficiently.
   * Optimized Triggers: Offers SKIP LOCKED for row-level triggers, which can improve concurrency in some situations.

Note that the descriptions above provide only a high-level overview of the important changes in each major version. There are many other smaller features, improvements, and bug fixes in each release. For a comprehensive list, please refer to the official PostgreSQL release notes: [https://www.postgresql.org/docs/release/](https://www.postgresql.org/docs/release/)
