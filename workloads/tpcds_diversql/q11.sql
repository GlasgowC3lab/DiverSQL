WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_net_loss,
        dd.d_year,
        i.i_brand,
        i.i_color,
        i.i_item_desc,
        i.i_product_name,
        st.s_store_name
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    WHERE regexp_like(i.i_brand, '(?i)corp')
      AND i.i_item_desc LIKE '%size%'
)
SELECT
    concat(fr.i_brand, '-', fr.i_color) AS brand_color,
    count(*) AS return_cnt,
    sum(fr.sr_net_loss) AS total_net_loss,
    avg(fr.sr_net_loss) AS avg_net_loss,
    max(fr.d_year) AS latest_year,
    substring(fr.i_item_desc, 1, 15) AS short_desc
FROM filtered_returns fr
WHERE fr.d_year = (SELECT MAX(d_year) FROM date_dim)
GROUP BY
    concat(fr.i_brand, '-', fr.i_color),
    substring(fr.i_item_desc, 1, 15)
ORDER BY total_net_loss DESC
LIMIT 100
