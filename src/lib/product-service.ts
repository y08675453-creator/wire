import { supabase, isSupabaseConfigured } from './supabase';
import { Product } from './products-data';

export const getProducts = async (): Promise<Product[]> => {
  if (!isSupabaseConfigured) {
    return [];
  }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching products:', error);
      return [];
    }

    return (data || []).map(p => ({
      id: p.id,
      name: p.name,
      brand: p.brand,
      category: p.category,
      color: p.colors || [],
      description: p.description || '',
      specifications: p.specifications || {},
      basePrice: parseFloat(p.base_price),
      unitType: p.unit_type as 'metres' | 'coils',
      stockQuantity: p.stock_quantity || 0,
      imageUrl: p.image_url || '',
      brochureUrl: p.brochure_url,
      isActive: p.is_active,
    }));
  } catch (error) {
    console.error('Failed to fetch products:', error);
    return [];
  }
};

export const getAllProducts = async (): Promise<Product[]> => {
  if (!isSupabaseConfigured) {
    return [];
  }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching all products:', error);
      return [];
    }

    return (data || []).map(p => ({
      id: p.id,
      name: p.name,
      brand: p.brand,
      category: p.category,
      color: p.colors || [],
      description: p.description || '',
      specifications: p.specifications || {},
      basePrice: parseFloat(p.base_price),
      unitType: p.unit_type as 'metres' | 'coils',
      stockQuantity: p.stock_quantity || 0,
      imageUrl: p.image_url || '',
      brochureUrl: p.brochure_url,
      isActive: p.is_active,
    }));
  } catch (error) {
    console.error('Failed to fetch all products:', error);
    return [];
  }
};

export const getProductById = async (id: string): Promise<Product | null> => {
  if (!isSupabaseConfigured) {
    return null;
  }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error || !data) {
      console.error('Error fetching product:', error);
      return null;
    }

    return {
      id: data.id,
      name: data.name,
      brand: data.brand,
      category: data.category,
      color: data.colors || [],
      description: data.description || '',
      specifications: data.specifications || {},
      basePrice: parseFloat(data.base_price),
      unitType: data.unit_type as 'metres' | 'coils',
      stockQuantity: data.stock_quantity || 0,
      imageUrl: data.image_url || '',
      brochureUrl: data.brochure_url,
      isActive: data.is_active,
    };
  } catch (error) {
    console.error('Failed to fetch product:', error);
    return null;
  }
};

export const saveProduct = async (product: Omit<Product, 'id'> & { id?: string }): Promise<Product | null> => {
  if (!isSupabaseConfigured) {
    return null;
  }

  try {
    const productData = {
      name: product.name,
      brand: product.brand,
      category: product.category,
      colors: product.color,
      description: product.description,
      specifications: product.specifications,
      base_price: product.basePrice,
      unit_type: product.unitType,
      stock_quantity: product.stockQuantity,
      image_url: product.imageUrl,
      brochure_url: product.brochureUrl,
      is_active: product.isActive,
      updated_at: new Date().toISOString(),
    };

    if (product.id) {
      const { data, error } = await supabase
        .from('products')
        .update(productData)
        .eq('id', product.id)
        .select()
        .single();

      if (error) {
        console.error('Error updating product:', error);
        throw error;
      }

      return {
        id: data.id,
        name: data.name,
        brand: data.brand,
        category: data.category,
        color: data.colors || [],
        description: data.description || '',
        specifications: data.specifications || {},
        basePrice: parseFloat(data.base_price),
        unitType: data.unit_type as 'metres' | 'coils',
        stockQuantity: data.stock_quantity || 0,
        imageUrl: data.image_url || '',
        brochureUrl: data.brochure_url,
        isActive: data.is_active,
      };
    } else {
      const { data, error } = await supabase
        .from('products')
        .insert(productData)
        .select()
        .single();

      if (error) {
        console.error('Error creating product:', error);
        throw error;
      }

      return {
        id: data.id,
        name: data.name,
        brand: data.brand,
        category: data.category,
        color: data.colors || [],
        description: data.description || '',
        specifications: data.specifications || {},
        basePrice: parseFloat(data.base_price),
        unitType: data.unit_type as 'metres' | 'coils',
        stockQuantity: data.stock_quantity || 0,
        imageUrl: data.image_url || '',
        brochureUrl: data.brochure_url,
        isActive: data.is_active,
      };
    }
  } catch (error) {
    console.error('Failed to save product:', error);
    throw error;
  }
};

export const deleteProduct = async (id: string): Promise<boolean> => {
  if (!isSupabaseConfigured) {
    return false;
  }

  try {
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting product:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Failed to delete product:', error);
    return false;
  }
};

export const uploadProductImage = async (file: File): Promise<string | null> => {
  if (!isSupabaseConfigured) {
    return null;
  }

  try {
    const fileExt = file.name.split('.').pop();
    const fileName = `product-${Date.now()}.${fileExt}`;
    const filePath = `products/${fileName}`;

    const { error: uploadError } = await supabase.storage
      .from('product-images')
      .upload(filePath, file);

    if (uploadError) {
      console.error('Upload error:', uploadError);
      throw uploadError;
    }

    const { data: urlData } = supabase.storage
      .from('product-images')
      .getPublicUrl(filePath);

    return urlData.publicUrl;
  } catch (error) {
    console.error('Failed to upload image:', error);
    throw error;
  }
};
