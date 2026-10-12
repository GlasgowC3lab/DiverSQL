WITH inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 0
),
sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        ws.web_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(ia.total_on_hand) AS total_on_hand
    FROM inv_agg ia
    JOIN date_dim d
        ON ia.inv_date_sk = d.d_date_sk
    JOIN item i
        ON ia.inv_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND r.r_reason_desc LIKE '%service%'
    GROUP BY CUBE (s.s_store_name, i.i_category, d.d_month_seq, d.d_year, ws.web_name)
)
SELECT
    s_store_name,
    i_category,
    d_year,
    d_month_seq,
    web_name,
    total_sales,
    total_return_amount,
    total_on_hand,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year
FROM sales_agg
ORDER BY d_year, sales_rank_year, s_store_name
