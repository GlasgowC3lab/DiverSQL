WITH class_sales AS (
    SELECT ca_state,
           i_class,
           t_shift,
           SUM(ss_ext_sales_price) AS total_sales,
           AVG(ss_ext_discount_amt) AS avg_discount
    FROM store_sales
    JOIN customer_address ON ss_addr_sk = ca_address_sk
    JOIN item ON ss_item_sk = i_item_sk
    JOIN time_dim ON ss_sold_time_sk = t_time_sk
    GROUP BY ca_state, i_class, t_shift
), ranked_sales AS (
    SELECT ca_state,
           i_class,
           t_shift,
           total_sales,
           avg_discount,
           DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS state_dense_rank,
           NTILE(4) OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_quartile
    FROM class_sales
)
SELECT ca_state,
       i_class,
       t_shift,
       total_sales,
       avg_discount,
       state_dense_rank,
       sales_quartile,
       CASE WHEN sales_quartile = 1 THEN 'Top Quartile' ELSE 'Other Quartile' END AS quartile_label
FROM ranked_sales
WHERE state_dense_rank <= 3                     -- keep only top‑3 classes per state
ORDER BY ca_state, state_dense_rank
