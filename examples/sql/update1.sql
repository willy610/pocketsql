UPDATE 
  './examples/data/s.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  SET SupplierName = 'Updated', City = 'Lerwick'

  WHERE Supplier.Status = '20' ;