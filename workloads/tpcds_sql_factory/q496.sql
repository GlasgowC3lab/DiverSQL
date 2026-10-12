WITH item_quarter_sales AS (
    SELECT
        ss.ss_item_sk,
        d.d_year,
        d.d_quarter_seq,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON d.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'Promotion'
    GROUP BY ss.ss_item_sk, d.d_year, d.d_quarter_seq
),
ranked_items AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_net_paid DESC) AS quarterly_rank
    FROM item_quarter_sales
),
avg_discount_per_item AS (
    SELECT
        ss_item_sk,
        AVG(total_discount / NULLIF(sales_cnt, 0)) AS avg_discount_per_sale
    FROM item_quarter_sales
    GROUP BY ss_item_sk
)
SELECT
    ri.ss_item_sk,
    ri.d_year,
    ri.d_quarter_seq,
    ri.total_net_paid,
    ri.total_discount,
    ri.sales_cnt,
    CASE 
        WHEN ad.avg_discount_per_sale IS NULL THEN 'No Discount Data'
        WHEN (ri.total_discount / NULLIF(ri.sales_cnt, 0)) > ad.avg_discount_per_sale THEN 'Above Avg Discount'
        ELSE 'Below Avg Discount'
    END AS discount_flag,
    ad.avg_discount_per_sale,
    ri.quarterly_rank
FROM ranked_items ri
JOIN avg_discount_per_item ad ON ri.ss_item_sk = ad.ss_item_sk
WHERE ri.quarterly_rank <= 5
ORDER BY ri.d_year, ri.d_quarter_seq, ri.quarterly_rank
