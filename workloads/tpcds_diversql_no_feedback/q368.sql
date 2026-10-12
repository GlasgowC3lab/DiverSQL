WITH item_returns AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_color,
        i.i_units,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        s.s_store_id,
        s.s_state,
        r.r_reason_desc,
        ca.ca_suite_number,
        ca.ca_country
    FROM tpcds.item i
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE i.i_color = 'pink'
      AND inv.inv_quantity_on_hand > 500
      AND ca.ca_country = 'United States'
      AND s.s_state = 'CA'
)
SELECT
    i_item_id,
    i_item_desc,
    i_color,
    i_units,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(wr_return_amt) AS total_web_return_amt,
    SUM(sr_return_amt) + SUM(wr_return_amt) AS total_return_amt,
    AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(DISTINCT s_store_id) AS store_count,
    SUM(CASE WHEN sr_return_amt > 100 THEN sr_return_amt ELSE 0 END) AS high_store_return_sum,
    SUM(CASE WHEN wr_return_amt > 100 THEN wr_return_amt ELSE 0 END) AS high_web_return_sum
FROM item_returns
GROUP BY
    i_item_id,
    i_item_desc,
    i_color,
    i_units
HAVING
    SUM(sr_return_amt) + SUM(wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
