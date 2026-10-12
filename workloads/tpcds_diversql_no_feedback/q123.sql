WITH unified_returns AS (
    SELECT 
        c.c_customer_id,
        i.i_category_id,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        r.r_reason_desc,
        CASE WHEN sr.sr_return_amt > 200 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_class_id IN (4, 7)
      AND i.i_manager_id = 25
      AND r.r_reason_desc = 'Did not like the color'
      AND c.c_birth_month = 6
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count > 2
    UNION DISTINCT
    SELECT 
        c.c_customer_id,
        i.i_category_id,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        r.r_reason_desc,
        CASE WHEN sr.sr_return_amt > 200 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_class_id = 1
      AND i.i_manager_id = 6
      AND c.c_birth_month = 3
      AND ca.ca_state = 'TX'
      AND hd.hd_vehicle_count = 0
      AND sr.sr_return_amt > 50
)
SELECT
    c_customer_id,
    COUNT(*) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_quantity,
    MIN(sr_return_amt) AS min_return_amount,
    MAX(sr_return_amt) AS max_return_amount,
    CASE WHEN SUM(sr_return_amt) > (
            SELECT SUM(sr_return_amt) FROM store_returns WHERE sr_return_amt > 500
        ) THEN 'Above High Total' ELSE 'Normal' END AS total_category
FROM unified_returns
WHERE i_category_id = (
        SELECT MAX(i_category_id) FROM item WHERE i_class_id = 4
    )
GROUP BY c_customer_id
ORDER BY total_return_amount DESC
LIMIT 100
