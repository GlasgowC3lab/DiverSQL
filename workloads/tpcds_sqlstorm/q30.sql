WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        st.s_store_name,
        it.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN item it ON ss.ss_item_sk = it.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, st.s_store_name, it.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        cc.cc_name AS channel_name,
        it.i_category,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item it ON cs.cs_item_sk = it.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, cc.cc_name, it.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        st.s_store_name,
        it.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN item it ON sr.sr_item_sk = it.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, st.s_store_name, it.i_category
),
combined_sales AS (
    SELECT
        d_year,
        month,
        s_store_name AS entity_name,
        i_category,
        total_sales,
        total_profit
    FROM store_sales_agg
    UNION ALL
    SELECT
        d_year,
        month,
        channel_name AS entity_name,
        i_category,
        total_sales,
        total_profit
    FROM catalog_sales_agg
)
SELECT
    cs.d_year,
    cs.month,
    cs.entity_name,
    cs.i_category,
    cs.total_sales,
    cs.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    cs.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales_after_returns
FROM combined_sales cs
LEFT JOIN returns_agg r
    ON cs.d_year = r.d_year
   AND cs.month = r.month
   AND cs.entity_name = r.s_store_name
   AND cs.i_category = r.i_category
ORDER BY cs.d_year, cs.month, cs.entity_name, cs.i_category
