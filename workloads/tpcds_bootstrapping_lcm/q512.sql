WITH returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_city AS store_city,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        cp.cp_catalog_page_id AS catalog_page_id,
        cp.cp_catalog_page_number AS catalog_page_number,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        d_promo_end.d_date AS promo_end_date,
        d_cp_end.d_date AS catalog_end_date,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        COUNT(DISTINCT wr.wr_item_sk) AS distinct_items,
        MIN(d_ret.d_date) AS first_return_date,
        MAX(d_ret.d_date) AS last_return_date
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_ret.d_date_sk <= d_promo_end.d_date_sk
      AND d_ret.d_date_sk <= d_cp_end.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_city,
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_promo_end.d_date,
        d_cp_end.d_date
)
SELECT
    store_id,
    store_city,
    promo_id,
    promo_name,
    catalog_page_id,
    catalog_page_number,
    return_year,
    return_month,
    promo_end_date,
    catalog_end_date,
    total_return_amount,
    total_net_loss,
    total_return_qty,
    distinct_orders,
    distinct_items,
    first_return_date,
    last_return_date,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rank
FROM returns_agg
ORDER BY rank
LIMIT 100
