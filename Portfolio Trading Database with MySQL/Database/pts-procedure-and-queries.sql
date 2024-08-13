/* stored procedure - how assets are added to a user's portfolio - include the creation of portfolio with deposit */
DELIMITER //
CREATE PROCEDURE placeTrade(IN portfolioId INT, IN tradeDate DATETIME(0), IN typeId INT, IN fiId INT, 
                            IN tradeQty DECIMAL(18,6), IN tradeTotal DECIMAL(18,6), OUT createdTradeId INT)
newTrade: BEGIN
    DECLARE availableQty DECIMAL(18,6) DEFAULT NULL;
    DECLARE availableTotal DECIMAL (18,6) DEFAULT NULL;
    DECLARE portfolioValuation DECIMAL (18,6) DEFAULT NULL;
    DECLARE portfolioMoney DECIMAL (18,6) DEFAULT NULL;

    /* Declaring exit handler for violating different constraints */
    DECLARE EXIT HANDLER FOR 1452, 1048
    BEGIN
        DECLARE trueTypeId INT DEFAULT NULL;
        DECLARE truePortfolioId INT DEFAULT NULL;
        DECLARE trueFiId INT DEFAULT NULL;
        
        SELECT portfolio_id FROM portfolio 
        WHERE portfolio_id = portfolioId INTO truePortfolioId;
        IF ISNULL(truePortfolioId) THEN
            SELECT CONCAT("Error: portfolioId ", portfolioId, 
                          " does not exist in the database");
        END IF;

        SELECT type_id FROM trade_types 
        WHERE type_id = typeId INTO trueTypeId;
        IF ISNULL(trueTypeId) THEN
            SELECT CONCAT("Error: typeId ", typeId, 
                          " does not exist in the database");
        END IF;

        SELECT fi_id FROM financial_instruments 
        WHERE fi_id = fiId INTO trueFiId;
        IF ISNULL(trueFiId) THEN
            SELECT CONCAT("Error: fiId ", fiId, 
                          " does not exist in the database");
        END IF;

        ROLLBACK;
        SET createdTradeId= -1;
    END;
    
    /* Implementing transaction */
    START TRANSACTION;

    /* Handling the case where quantity passed is more than the amount in the portolio */
    IF tradeQty <= 0 THEN
        ROLLBACK;
        SET createdTradeId = -1;
        SELECT CONCAT("Error: qty ", tradeQty, " ordered should be more than 0");
        LEAVE newTrade;
    END IF;

    /* Deposit */
    IF typeId = 0 THEN
        /* Creating dollar record for the portfolio if missing */
        SELECT asset_qty FROM assets
        WHERE fi_id = 0 AND portfolio_id = portfolioId
        INTO availableQty;

        IF ISNULL(availableQty) THEN
            INSERT INTO assets (portfolio_id, fi_id, asset_qty) VALUES(portfolioId, 0, 0.0);
        END IF;

        /* Ensuring that only dollars can be deposited */
        IF fiId != 0 THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: cannot deposit anything except dollars ");
            LEAVE newTrade;
        END IF;

        IF tradeQty != tradeTotal THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: quantity of dollars deposited should be the same as total");
            LEAVE newTrade;
        END IF;

        /*Updating assets */
        UPDATE assets 
           SET asset_qty = asset_qty + tradeTotal 
        WHERE portfolio_id = portfolioId
          AND fi_id = 0;

    END IF;
    
    /* Withdrawal */
    IF typeId = 1 THEN
       /* Selecting the available dollars on the account for withdrawal */
        SELECT asset_qty FROM assets
        WHERE fi_id = 0 AND portfolio_id = portfolioId
        INTO availableQty;

        /* Handling case where amount requested for withdrawal is more than the dollar amount available */
        IF ISNULL(availableQty) OR tradeQty < availableQty THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: withdrawal total ", tradeQty, " is bigger than the available dollars: ", availableQty);
            LEAVE newTrade;
        END IF;

        /* Ensuring that only dollars can be withdrawn */
        IF fiId != 0 THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: cannot withdraw anything except dollars ");
            LEAVE newTrade;
        END IF;

        IF tradeQty != tradeTotal THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: quantity of dollars withdrawn should be the same as total");
            LEAVE newTrade;
        END IF;

         /* Updating assets */
        UPDATE assets 
           SET asset_qty = asset_qty - tradeTotal 
        WHERE portfolio_id = portfolioId
          AND fi_id = 0;
          
    END IF;

    /* SELL */
    IF typeId = 2 THEN
        /* Selecting the asset quantity to be used for the trade */
        SELECT asset_qty FROM assets
        WHERE fi_id = fiId AND portfolio_id = portfolioId
        INTO availableQty;

        /* Handling case where quantity ordered is more than the available user assets; 
           for simplification, I am not checking that there are assets available on the 
           day of trade */
        IF ISNULL(availableQty) OR tradeQty < availableQty THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: qty ", tradeQty, " is less than the available assets: ", availableQty);
            LEAVE newTrade;
        END IF;

        /* Creating dollar record for the portfolio if missing */
        SELECT asset_qty FROM assets
        WHERE fi_id = 0 AND portfolio_id = portfolioId
        INTO availableTotal;

        IF ISNULL(availableTotal) THEN
            INSERT INTO assets (portfolio_id, fi_id, asset_qty) VALUES (portfolioId, 0, 0.0);
        END IF;

         /* Updating assets */
        UPDATE assets 
           SET asset_qty = asset_qty - tradeQty
        WHERE portfolio_id = portfolioId
          AND fi_id = fiId;

        UPDATE assets 
           SET asset_qty = asset_qty + tradeTotal 
        WHERE portfolio_id = portfolioId
          AND fi_id = 0;

    END IF;

    /* BUY */
    IF typeId = 3 THEN
        /* Selecting the asset quantity to be used for the trade */
        SELECT asset_qty FROM assets
        WHERE fi_id = 0 AND portfolio_id = portfolioId
        INTO availableTotal;

        /* Handling case where quantity ordered is more than the available user assets; 
           for simplification, I am not checking that there is money available on the 
           day of trade */
        IF ISNULL(availableTotal) OR tradeTotal < availableQty THEN
            ROLLBACK;
            SET createdTradeId = -1;
            SELECT CONCAT("Error: transaction total ", tradeTotal, " is bigger than the available dollars: ", availableQty);
            LEAVE newTrade;
        END IF;

         /* Creating asset record for the portfolio if missing */
        SELECT asset_qty FROM assets
        WHERE fi_id = fiId AND portfolio_id = portfolioId
        INTO availableQty;

        IF ISNULL(availableQty) THEN
            INSERT INTO assets (portfolio_id, fi_id, asset_qty) VALUES(portfolioId, fiId, 0.0);
        END IF;

        /* Updating assets */
        UPDATE assets 
           SET asset_qty = asset_qty + tradeQty 
        WHERE portfolio_id = portfolioId
          AND fi_id = fiId;

        UPDATE assets 
           SET asset_qty = asset_qty - tradeTotal 
        WHERE portfolio_id = portfolioId
          AND fi_id = 0;

    END IF;
    
    /* Inserting values into tables */
    INSERT INTO trades (portfolio_id, trade_date, type_id, fi_id, trade_qty, price, total)
    VALUES (portfolioId, tradeDate, typeId, fiId, tradeQty, tradeTotal/tradeQty, tradeTotal);
    SET createdTradeId = LAST_INSERT_ID();

    /* Calculating the portfolio valuation, and simplifying assuming current date is greater than any 
    date for which we have pricing for */
    SELECT SUM(a.asset_qty * ip.close)
    FROM assets as a 
    INNER JOIN instrument_prices AS ip ON ip.fi_id=a.fi_id
    WHERE a.portfolio_id = portfolioId 
      AND pricing_date = (
        SELECT MAX(pricing_date)
        FROM instrument_prices AS ip2
        WHERE a.fi_id = ip2.fi_id
        AND ip.fi_id = ip2.fi_id
    )
    INTO portfolioValuation;

    /*updating the asset quantities according to the trade */
    SELECT asset_qty 
    FROM assets 
    WHERE portfolio_id = portfolioId 
      AND fi_id = 0
    INTO portfolioMoney;

    /*updating portfolio valuation */
    UPDATE portfolio 
       SET valuation = portfolioValuation + portfolioMoney 
    WHERE portfolio_id = portfolioId;

    COMMIT;
END //

DELIMITER ;

CALL placeTrade(30, '2023-03-09', 3, 30, 5, 100, @trade_id);
SELECT * FROM assets WHERE portfolio_id = 30;
SELECT * FROM portfolio WHERE portfolio_id = 30;
SELECT pricing_date, close FROM instrument_prices WHERE fi_id = 30 ORDER BY pricing_date DESC LIMIT 5;

/* Queries */

/* what is the latest stock closing price for a specific stock */ 
SELECT pricing_date, close
    FROM instrument_prices as ip
    WHERE pricing_date = (
        SELECT MAX(pricing_date)
        FROM instrument_prices AS ip2 
        INNER JOIN financial_instruments AS fi
        ON fi.fi_id=ip.fi_id
        WHERE fi.symbol = 'AAPL'
        AND ip.fi_id = ip2.fi_id
    );

/* what is the latest closing price for all stocks */ 
SELECT fi.symbol, ip.* 
FROM instrument_prices AS ip
INNER JOIN financial_instruments as fi ON fi.fi_id=ip.fi_id
WHERE pricing_date = (
    SELECT MAX(pricing_date)
    FROM instrument_prices AS ip2 
    WHERE ip.fi_id = ip2.fi_id
    );

/* what is the current valuaton of a user's portfolio */
SELECT valuation FROM portfolio WHERE user_id = 10;

/* calculating the current valuation of a portfolio without addressing the stored value */ 
 SELECT SUM(a.asset_qty * ip.close)
    FROM assets as a 
    INNER JOIN instrument_prices AS ip ON ip.fi_id=a.fi_id
    WHERE a.portfolio_id = 10
      AND pricing_date = (
        SELECT MAX(pricing_date)
        FROM instrument_prices AS ip2
        WHERE a.fi_id = ip2.fi_id
        AND ip.fi_id = ip2.fi_id
    );

/*however, the above does not include money valuation, so we need to include the following query, and adding both together
gives the total portfolio valuation */ 
SELECT asset_qty 
    FROM assets 
    WHERE portfolio_id = 10 
      AND fi_id = 0;

/* what user has the highest valued portfolio */
SELECT first_name, last_name, email, p.portfolio_id
FROM users AS u
INNER JOIN portfolio AS p ON p.user_id=u.user_id
ORDER BY p.valuation DESC
LIMIT 5;


/* the company with the highest trading volume within all available dates in billions*/ GOOD
SELECT fi.symbol, ip.close, ip.pricing_date, ip.volume * ip.close / 1000000000 AS traded_volume
    FROM instrument_prices as ip
    INNER JOIN financial_instruments AS fi
    ON fi.fi_id=ip.fi_id
    WHERE ip.volume * ip.close = (
        SELECT MAX(ip2.volume * ip2.close)
        FROM instrument_prices AS ip2
    );
