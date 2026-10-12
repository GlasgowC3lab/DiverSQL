select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 823 and 823+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'puff') and 
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'olive' or i_color = 'turquoise') and
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'snow') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'navy') and
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'chocolate') and 
        (i_units = 'Cup' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'rosy') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'rose') and
        (i_units = 'Gross' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'smoke') and
        (i_units = 'Unknown' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100
