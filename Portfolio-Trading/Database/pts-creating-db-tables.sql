/* Creating the database and creating tables */ 
CREATE SCHEMA portfolio_trading_support;

USE portfolio_trading_support;

CREATE TABLE financial_instruments (
    fi_id INT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(5) UNIQUE NOT NULL,
    industry VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    PRIMARY KEY (fi_id)
);

CREATE TABLE instrument_prices (
    fi_id INT UNSIGNED NOT NULL,
    pricing_date DATE NOT NULL,
    open DECIMAL(18,6) NOT NULL,
    high DECIMAL(18,6) NOT NULL,
    low DECIMAL(18,6) NOT NULL,
    close DECIMAL(18,6) NOT NULL,
    volume BIGINT NOT NULL,
    dividends DECIMAL(18,6),
    FOREIGN KEY (fi_id)
        REFERENCES financial_instruments(fi_id)
        ON DELETE CASCADE,
    PRIMARY KEY (fi_id, pricing_date)
);

CREATE TABLE trade_types (
    type_id INT UNSIGNED NOT NULL,
    type_name VARCHAR(10) NOT NULL,
    PRIMARY KEY (type_id)
);

CREATE TABLE users (
    user_id INT UNSIGNED NOT NULL,
    user_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(250) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id)
);

CREATE TABLE portfolio (
    portfolio_id INT UNSIGNED NOT NULL,
    valuation DECIMAL(18,6),
    user_id INT UNSIGNED NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (portfolio_id)
);

CREATE TABLE trades (
    trade_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    portfolio_id INT UNSIGNED NOT NULL,
    trade_date DATETIME(0) NOT NULL,
    type_id INT UNSIGNED NOT NULL,
    fi_id INT UNSIGNED NOT NULL,
    trade_qty DECIMAL(18,6) NOT NULL,
    price DECIMAL(18,6) NOT NULL,
    total DECIMAL(18,6) NOT NULL,
    FOREIGN KEY (portfolio_id)
        REFERENCES portfolio(portfolio_id)
        ON DELETE CASCADE,
    FOREIGN KEY (type_id)
        REFERENCES trade_types(type_id),
    FOREIGN KEY (fi_id)
        REFERENCES financial_instruments(fi_id), 
    PRIMARY KEY (trade_id)
);

CREATE TABLE assets (
    portfolio_id INT UNSIGNED NOT NULL,
    fi_id INT UNSIGNED NOT NULL,
    asset_qty DECIMAL(18,6),
    FOREIGN KEY (portfolio_id)
        REFERENCES portfolio(portfolio_id)
        ON DELETE CASCADE,
    FOREIGN KEY (fi_id)
        REFERENCES financial_instruments(fi_id),
    PRIMARY KEY (portfolio_id, fi_id)
);
