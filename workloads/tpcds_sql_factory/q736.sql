WITH class_sales AS (
    SELECT ca_state,
           i_class,
           t_shift,
           SUM(ss_ext_sales_price) AS total_sales,
           AVG(ss_ext_discount_amt) AS avg_discount,
           COUNT(*) AS transaction_cnt
    FROM store_sales
    JOIN customer_address ON ss_addr_sk = ca_address_sk
    JOIN item ON ss_item_sk = i_item_sk
    JOIN time_dim ON ss_sold_time_sk = t_time_sk
    WHERE ss_ext_discount_amt > 0                     -- only sales with a discount
    GROUP BY ca_state, i_class, t_shift
    HAVING COUNT(*) >= 10                             -- keep only classes with at least 10 transactions
)
SELECT ca_state,
       i_class,
       t_shift,
       total_sales,
       avg_discount,
       transaction_cnt,
       ROW_NUMBER() OVER (PARTITION BY ca_state, t_shift ORDER BY avg_discount ASC) AS discount_rank,
       SUM(total_sales) OVER (PARTITION BY ca_state, t_shift ORDER BY total_sales DESC ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS rolling_sales
FROM class_sales
ORDER BY ca_state, t_shift, discount_rank
