WITH class_sales AS (
    SELECT ca_state,
           i_class,
           t_shift,
           SUM(ss_ext_sales_price) AS total_sales,
           AVG(ss_ext_discount_amt) AS avg_discount,
           MAX(ss_net_profit) AS max_profit
    FROM store_sales
    JOIN customer_address ON ss_addr_sk = ca_address_sk
    JOIN item ON ss_item_sk = i_item_sk
    JOIN time_dim ON ss_sold_time_sk = t_time_sk
    WHERE ca_state IN ('CA', 'NY', 'TX')               -- focus on three states
    GROUP BY ca_state, i_class, t_shift
)
SELECT ca_state,
       i_class,
       t_shift,
       total_sales,
       avg_discount,
       max_profit,
       PERCENT_RANK() OVER (PARTITION BY ca_state ORDER BY max_profit ASC) AS profit_percentile,
       CASE WHEN avg_discount BETWEEN 0 AND 5 THEN 'Low'
            WHEN avg_discount BETWEEN 5 AND 15 THEN 'Medium'
            ELSE 'High' END AS discount_level
FROM class_sales
ORDER BY ca_state, profit_percentile DESC
