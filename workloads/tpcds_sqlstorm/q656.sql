WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_net_paid_inc_tax AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        ss_promo_sk AS promo_sk,
        ss_store_sk AS loc_sk,
        'store' AS loc_type,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_net_paid_inc_tax,
        cs_net_profit,
        cs_quantity,
        cs_promo_sk,
        cs_call_center_sk,
        'call_center',
        'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_paid_inc_tax,
        ws_net_profit,
        ws_quantity,
        ws_promo_sk,
        ws_web_site_sk,
        'web_site',
        'web'
    FROM web_sales
),
returns_union AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        sr_item_sk AS item_sk,
        sr_return_amt_inc_tax AS return_amount,
        sr_net_loss AS net_loss,
        sr_return_quantity AS return_quantity,
        'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_return_amt_inc_tax,
        cr_net_loss,
        cr_return_quantity,
        'catalog'
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_return_amt_inc_tax,
        wr_net_loss,
        wr_return_quantity,
        'web'
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_id,
        i.i_category,
        i.i_brand,
        s.channel,
        COALESCE(loc.name, 'UNKNOWN') AS location_name,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.quantity) AS total_quantity,
        SUM(CASE WHEN s.promo_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS promo_net_paid
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN (
        SELECT loc_sk, loc_type, name FROM (
            SELECT s_store_sk AS loc_sk, 'store' AS loc_type, s_store_name AS name FROM store
            UNION ALL
            SELECT cc_call_center_sk, 'call_center', cc_name FROM call_center
            UNION ALL
            SELECT web_site_sk, 'web_site', web_name FROM web_site
        )
    ) loc ON s.loc_sk = loc.loc_sk AND s.loc_type = loc.loc_type
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        s.channel,
        loc.name
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_id,
        i.i_category,
        i.i_brand,
        r.channel,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.net_loss) AS total_net_loss,
        SUM(r.return_quantity) AS total_return_quantity
    FROM returns_union r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        r.channel
),
combined AS (
    SELECT
        s.d_year,
        s.month_id,
        s.i_category,
        s.i_brand,
        s.channel,
        s.location_name,
        s.total_net_paid,
        s.total_net_profit,
        s.total_quantity,
        s.promo_net_paid,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.month_id = r.month_id
        AND s.i_category = r.i_category
        AND s.i_brand = r.i_brand
        AND s.channel = r.channel
)
SELECT
    d_year,
    month_id,
    i_category,
    i_brand,
    channel,
    location_name,
    total_net_paid,
    total_net_profit,
    total_quantity,
    promo_net_paid,
    total_return_amount,
    total_net_loss,
    total_return_quantity,
    (total_net_profit / NULLIF(total_net_paid, 0)) * 100 AS profit_pct_of_sales,
    total_net_profit - total_net_loss AS net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY d_year, month_id ORDER BY total_net_profit DESC) AS profit_rank_in_month
FROM combined
WHERE d_year BETWEEN 1998 AND 2002
ORDER BY d_year, month_id, total_net_profit DESC
LIMIT 1000
