SELECT
    i.i_brand,
    ib.ib_income_band_sk,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    AVG(ss.ss_quantity) AS avg_quantity_sold
FROM
    store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
WHERE
    regexp_like(i.i_item_desc, '[0-9]{3}')
    AND ca.ca_city LIKE 'New%'
    AND ss.ss_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand_id BETWEEN 10 AND 20)
    AND hd.hd_income_band_sk IN (SELECT ib2.ib_income_band_sk FROM income_band ib2 WHERE ib2.ib_lower_bound > 50000)
GROUP BY
    i.i_brand,
    ib.ib_income_band_sk,
    CONCAT(ca.ca_city, ', ', ca.ca_state)
ORDER BY
    total_net_profit DESC
LIMIT 100
