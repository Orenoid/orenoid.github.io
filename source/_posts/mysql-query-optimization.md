---
title: >-
  Recalling a MySQL Query Performance Optimization in a Business Development Process
s: mysql-query-optimization
date: 2023-11-18 08:00:08
tags:
---

Recently, during the implementation of a new feature in our project, I encountered a performance bottleneck. After several rounds modifications to the revelant SQL queries, I ultimately addressed it. In the following sections, I will document the troubleshooting process and the solution.

I'll give some context information first before we dive into the performance issue. Our company's product is a software development management system similar to Jira. If you are familiar with Jira, then you must know about a key concept — the issue. Basically, you can think of it as a task, which can be created, have its properties updated, its status changed, or be deleted. For an issue, within our product, we store its values in a table called 'property_value'  (In reality, it's not named this. To avoid breaching confidentiality agreements, I will similarly alter some names of tables and variables in the following sections.) The structure of the table is as follows:

```sql
CREATE TABLE property_value (
    issue_id INT,
    property_id INT,
    value VARCHAR(255),
  	postition INT
);
```

As you can see, this is just a simple table design resembling to an Entity-Attribute-Value (EAV) model. On this basis, our product includes a property called "department property", where the stored value corresponds to some department IDs.  In addition to this, a table called "department_member" exists to store the relationship between departments and their respective members.

Building on this foundation, I needed to implement a new feature that allows users to control permissions through a list of departments within the issue's department property. For instance, let's assume there are two issues, A and B. Now, if I want only members of Department A to have the permission to modify Issue A, I can set the permission configuration so that only 'responsible department' members can update the issue. Then, I would set the 'responsible department' property value of Issue A to 'Department A'.
To perform the permission verification for a task, it's necessary to query the department list specified in the property value, as well as the users within those departments. Subsequently, to verify the permission, we can determine whether the current user belongs to any of those departments.

However, in most of our business scenarios, there are typically a number of issues that require permission verification. As a result, this necessitates an SQL query that includes a join across three tables, as follows:
```sql
select *
from issue
         join property_value on issue.id = property_value.issue_id
         join department_member on property_value.value = department_member.department_id
     where issue.id in (1, 2, 3, ) -- TODO
```
For your information, all three tables have been appropriately indexed to optimize the query conditions mentioned above, which we will not delve into further.
Then, not surprisingly, I encountered the first performance issue with this SQL. Actually, I didn't expect this SQL to be very fast. Regardless, it's still necessary to use EXPLAIN to see where the problem lies:


[//]: # (第一轮优化：将 field 合并 2、第二轮优化：)