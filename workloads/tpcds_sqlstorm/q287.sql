WITH
sales AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_call_center_sk AS store_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_net_profit AS profit,
        cs_quantity AS quantity,
        cs_net_paid AS net_paid,
        cs_ext_sales_price AS ext_sales_price,
        cs_coupon_amt AS coupon_amt,
        cs_ext_discount_amt AS ext_discount_amt,
        cs_promo_sk AS promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS date_sk,
        ws_warehouse_sk AS store_sk,
        ws_item_sk AS item_sk,
        ws_bill_customer_sk AS customer_sk,
        ws_net_profit AS profit,
        ws_quantity AS quantity,
        ws_net_paid AS net_paid,
        ws_ext_sales_price AS ext_sales_price,
        ws_coupon_amt AS coupon_amt,
        ws_ext_discount_amt AS ext_discount_amt,
        ws_promo_sk AS promo_sk
    FROM web_sales
    UNION ALL
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS store_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_net_profit AS profit,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_ext_sales_price AS ext_sales_price,
        ss_coupon_amt AS coupon_amt,
        ss_ext_discount_amt AS ext_discount_amt,
        ss_promo_sk AS promo_sk
    FROM store_sales
),
returns AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        sr_store_sk AS store_sk,
        sr_item_sk AS item_sk,
        sr_customer_sk AS customer_sk,
        sr_net_loss AS loss,
        sr_return_quantity AS return_qty
    FROM store_returns
    UNION ALL
    SELECT
        wr_returned_date_sk AS date_sk,
        wr_web_page_sk AS store_sk,
        wr_item_sk AS item_sk,
        wr_refunded_customer_sk AS customer_sk,
        wr_net_loss AS loss,
        wr_return_quantity AS return_qty
    FROM web_returns
    UNION ALL
    SELECT
        cr_returned_date_sk AS date_sk,
        cr_call_center_sk AS store_sk,
        cr_item_sk AS item_sk,
        cr_refunded_customer_sk AS customer_sk,
        cr_net_loss AS loss,
        cr_return_quantity AS return_qty
    FROM catalog_returns
),
agg_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.store_sk,
        i.i_category,
        i.i_brand,
        SUM(s.profit) AS total_profit,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.quantity) AS total_quantity,
        COUNT(DISTINCT s.customer_sk) AS distinct_customers,
        SUM(s.ext_sales_price) AS total_sales,
        SUM(s.coupon_amt) AS total_coupons,
        SUM(s.ext_discount_amt) AS total_discounts
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.store_sk, i.i_category, i.i_brand
),
agg_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.store_sk,
        i.i_category,
        i.i_brand,
        SUM(r.loss) AS total_loss,
        SUM(r.return_qty) AS total_return_qty
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, r.store_sk, i.i_category, i.i_brand
),
combined AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.store_sk,
        COALESCE(st.s_store_name, cc.cc_name, wh.w_warehouse_name, ws.web_name) AS store_name,
        s.i_category,
        s.i_brand,
        s.total_profit,
        COALESCE(r.total_loss, 0) AS total_loss,
        (s.total_profit - COALESCE(r.total_loss, 0)) AS net_profit,
        s.total_sales,
        s.total_coupons,
        s.total_discounts,
        s.total_quantity,
        s.distinct_customers,
        COALESCE(r.total_return_qty, 0) AS total_return_qty
    FROM agg_sales s
    LEFT JOIN agg_returns r
        ON s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.store_sk = r.store_sk
        AND s.i_category = r.i_category
        AND s.i_brand = r.i_brand
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON s.store_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse wh ON s.store_sk = wh.w_warehouse_sk
    LEFT JOIN web_site ws ON s.store_sk = ws.web_site_sk
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY d_year, d_month_seq, i_category ORDER BY net_profit DESC) AS category_rank
    FROM combined
)
SELECT
    d_year,
    d_month_seq,
    store_sk,
    store_name,
    i_category,
    i_brand,
    total_profit,
    total_loss,
    net_profit,
    total_sales,
    total_coupons,
    total_discounts,
    total_quantity,
    distinct_customers,
    total_return_qty,
    profit_rank,
    category_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_month_seq, profit_rank
