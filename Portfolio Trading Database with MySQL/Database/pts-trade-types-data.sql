/* Inserting data into tables that did not import data through.csv */
INSERT INTO trade_types(type_id, type_name)
VALUES
    (0, 'Deposit'),
    (1, 'Withdraw'),
    (2, 'Sell'),
    (3, 'Buy');