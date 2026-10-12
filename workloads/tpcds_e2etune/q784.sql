WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    cc.cc_name,
    cc.cc_market_manager,
    wp.wp_type,
    COUNT(DISTINCT c_refunded.c_customer_sk) AS distinct_refunded_customers,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY SUM(fr.cr_net_loss) DESC) AS net_loss_rank
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer c_refunded ON fr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN web_page wp ON wp.wp_customer_sk = c_refunded.c_customer_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_division = 2
  AND wp.wp_type IN ('Home', 'Product')
GROUP BY cc.cc_name, cc.cc_market_manager, wp.wp_type
HAVING SUM(fr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
