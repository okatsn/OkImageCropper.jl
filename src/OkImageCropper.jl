module OkImageCropper

using Images
using FileIO

export crop_whitespace

"""
    is_white(pixel::RGBX)
    is_white(pixel::Gray)

Checks if a pixel is white.
For RGBX types (like RGBA or RGB), it checks if R, G, and B components are at their maximum (typically 1.0 or 255).
For Gray types, it checks if the gray value is at its maximum.
"""
function is_white(pixel::RGBX)
    # Assuming white is (1.0, 1.0, 1.0) for Float types or (255, 255, 255) for N0f8
    # We check the color channels, ignoring alpha for the definition of "white background"
    return red(pixel) == oneunit(typeof(red(pixel))) &&
           green(pixel) == oneunit(typeof(green(pixel))) &&
           blue(pixel) == oneunit(typeof(blue(pixel)))
end

function is_white(pixel::Gray)
    return gray(pixel) == oneunit(typeof(gray(pixel)))
end

"""
    crop_whitespace(input_path::String, output_path::String; padding::Int=0, target_color=nothing)

Crops the white (or specified `target_color`) empty spaces from an image.

The function identifies the bounding box of pixels that are not white
(or not the `target_color`) and then crops the image to this bounding box,
optionally adding some padding.

# Arguments
- `input_path::String`: Path to the input image file (e.g., PNG).
- `output_path::String`: Path to save the cropped image.
- `padding::Int=0`: Optional padding (in pixels) to add around the cropped content.
- `target_color::Union{Nothing, RGBX, Gray}=nothing`: Optional. The color to treat as background.
  If `nothing` (default), it will use the `is_white` function to detect white pixels.
  You can provide a specific `RGB` or `Gray` color to be cropped. For example,
  `RGB{N0f8}(1.0,1.0,1.0)` for white.

# Returns
- `Bool`: `true` if cropping was successful and the file was saved, `false` otherwise.

# Example
```julia
using OkImageCropper

# Crop white space from input.png and save to output.png
crop_whitespace("input.png", "output.png")

# Crop with a 10-pixel padding
crop_whitespace("input.png", "output_padded.png", padding=10)

# Crop a specific background color (e.g., light gray if it was N0f8)
# using Images
# crop_whitespace("input.png", "output_gray_bg.png", target_color=RGB{N0f8}(0.9,0.9,0.9))
```
"""
function crop_whitespace(input_path::String, output_path::String; padding::Int=0, target_color::Union{Nothing,RGBX,Gray}=nothing)
    img = FileIO.load(input_path)
    img_matrix = channelview(img) # For RGB, this is Color x Height x Width
    # For Gray, this is Height x Width
    # Determine the check_pixel function based on target_color
    local check_pixel_is_background
    if isnothing(target_color)
        check_pixel_is_background = is_white
    else
        check_pixel_is_background = pixel -> (pixel == target_color)
    end

    # Transpose if colorview gives Color x H x W to make it easier to work with rows/cols
    # Standard matrix access is [row, col] which corresponds to [y, x]
    if img_matrix isa AbstractArray{<:Any,3} # e.g. RGB, RGBA
        # We need to check pixels, so reconstruct them first
        height, width = size(img, 1), size(img, 2)
    elseif img_matrix isa AbstractArray{<:Any,2} # e.g. Gray
        height, width = size(img_matrix)
    else
        @error "Unsupported image format or channel view."
        return false
    end

    min_r, max_r = height + 1, 0
    min_c, max_c = width + 1, 0
    found_content = false

    for r in 1:height
        for c in 1:width
            pixel = img[r, c] # Accessing pixel directly from img
            if !check_pixel_is_background(pixel)
                min_r = min(min_r, r)
                max_r = max(max_r, r)
                min_c = min(min_c, c)
                max_c = max(max_c, c)
                found_content = true
            end
        end
    end

    if !found_content
        @warn "No content found in the image (all pixels are background color). Saving original image."
        FileIO.save(output_path, img)
        return true
    end

    # Add padding
    min_r = max(1, min_r - padding)
    max_r = min(height, max_r + padding)
    min_c = max(1, min_c - padding)
    max_c = min(width, max_c + padding)

    # Ensure valid crop dimensions
    if min_r > max_r || min_c > max_c
        @warn "Padding is too large or content area is too small, resulting in invalid crop dimensions. Saving original image."
        FileIO.save(output_path, img)
        return true
    end

    cropped_img = img[min_r:max_r, min_c:max_c]
    FileIO.save(output_path, cropped_img)
    println("Cropped image saved to $output_path")
    return true
end

end # module OkImageCropper
