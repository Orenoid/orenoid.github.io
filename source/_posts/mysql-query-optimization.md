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

As you can see, this is just a simple table design resembling to an Entity-Attribute-Value (EAV) model. On this basis, our product includes a property called "department property", where the stored value corresponds to some department IDs.



The feature I was working on this time.
