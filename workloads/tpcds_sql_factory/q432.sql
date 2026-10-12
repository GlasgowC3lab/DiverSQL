WITH returns_by_addr AS (
    SELECT
        cr.cr_refunded_addr_sk AS address_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_addr_sk
),
sales_by_addr AS (
    SELECT
        ws.ws_ship_addr_sk AS address_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_quantity) AS total_sales_quantity
    FROM web_sales ws
    GROUP BY ws.ws_ship_addr_sk
)
SELECT
    ca.ca_city,
    rba.total_return_amount,
    sba.total_sales_amount,
    (sba.total_sales_amount - rba.total_return_amount) AS net_gain,
    CASE
        WHEN (sba.total_sales_amount - rba.total_return_amount) > 0 THEN 'Positive Net'
        WHEN (sba.total_sales_amount - rba.total_return_amount) < 0 THEN 'Negative Net'
        ELSE 'Break-even'
    END AS net_category,
    RANK() OVER (ORDER BY (sba.total_sales_amount - rba.total_return_amount) DESC) AS net_gain_rank
FROM returns_by_addr rba
INNER JOIN sales_by_addr sba
    ON rba.address_sk = sba.address_sk
INNER JOIN customer_address ca
    ON rba.address_sk = ca.ca_address_sk
