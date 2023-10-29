select rtrim(right(PhysicalName, charindex('\', reverse(PhysicalName)) - 1))
