# OkImageCropper

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://okatsn.github.io/OkImageCropper.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://okatsn.github.io/OkImageCropper.jl/dev/)
[![Build Status](https://github.com/okatsn/OkImageCropper.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/okatsn/OkImageCropper.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/okatsn/OkImageCropper.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/okatsn/OkImageCropper.jl)

<!-- Don't have any of your custom contents above; they won't occur if there is no citation. -->

## Documentation Badge is here:

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://okatsn.github.io/OkImageCropper.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://okatsn.github.io/OkImageCropper.jl/dev)

> See [Documenter.jl: Documentation Versions](https://documenter.juliadocs.org/dev/man/hosting/#Documentation-Versions)


## How to Use

1.  **Save the Code**: Save the code above into a file named `ImageCropper.jl` (or any name you prefer, like `image_cropper_utils.jl`).

2.  **Include and Use in Your Script**:
    You can then include and use this module in another Julia script or in the Julia REPL:

    ```julia
    # If ImageCropper.jl is in the same directory:
    include("OkImageCropper.jl")
    using OkImageCropper

    # Or if you made it a proper package, you'd do:
    # using ImageCropper

    # Example usage:
    # Create a dummy png file for testing
    using Images, FileIO, ImageCore

    # Create a white image with a black square in the middle
    img_width = 200
    img_height = 150
    white_pixel_rgb = RGB{N0f8}(1.0, 1.0, 1.0)
    black_pixel_rgb = RGB{N0f8}(0.0, 0.0, 0.0)
    test_img = fill(white_pixel_rgb, img_height, img_width)
    test_img[50:100, 70:130] .= black_pixel_rgb # Non-white content

    # Add some alpha channel
    test_img_rgba = RGBA.(test_img, N0f8(1.0))
    test_img_rgba[1:10, 1:10] .= RGBA{N0f8}(1.0,1.0,1.0,0.0) # some transparent white pixels

    save("test_input.png", test_img_rgba)

    # Create a grayscale image
    gray_img = fill(Gray{N0f8}(1.0), img_height, img_width) # White
    gray_img[60:90, 80:120] .= Gray{N0f8}(0.2) # Dark gray content
    save("test_gray_input.png", gray_img)

    println("Cropping RGB image...")
    success_rgb = crop_whitespace("test_input.png", "cropped_output.png")
    println("RGB Cropping successful: $success_rgb")

    println("\nCropping RGB image with padding...")
    success_rgb_padded = crop_whitespace("test_input.png", "cropped_output_padded.png", padding=10)
    println("RGB Padded Cropping successful: $success_rgb_padded")

    println("\nCropping Grayscale image...")
    success_gray = crop_whitespace("test_gray_input.png", "cropped_gray_output.png")
    println("Grayscale Cropping successful: $success_gray")

    println("\nCropping Grayscale image with custom background color (white)...")
    success_gray_custom = crop_whitespace("test_gray_input.png", "cropped_gray_custom_bg.png", target_color=Gray{N0f8}(1.0))
    println("Grayscale Custom BG Cropping successful: $success_gray_custom")

    println("\nAttempting to crop an all-white image...")
    all_white_img = fill(RGB{N0f8}(1.0,1.0,1.0), 50,50)
    save("all_white.png", all_white_img)
    success_all_white = crop_whitespace("all_white.png", "cropped_all_white.png")
    println("All-white crop attempt finished: $success_all_white")
    ```

---
## Explanation

1.  **Module Definition**: `module ImageCropper ... end` defines a new module.
2.  **Dependencies**:
    * `using Images`: For image types (like `RGB`, `Gray`, `RGBA`) and color manipulation functions (`red`, `green`, `blue`, `gray`, `alpha`).
    * `using FileIO`: For loading (`load`) and saving (`save`) images.
3.  **`export crop_whitespace`**: This makes the `crop_whitespace` function available when you do `using .ImageCropper`.
4.  **`is_white(pixel)` functions**:
    * These helper functions check if a given pixel is white.
    * It checks if the red, green, and blue components are at their maximum value (`oneunit` is used for generality, e.g., 1.0 for floating-point representations like `RGB{Float32}` or `N0f8(1.0)` which is 255 for `RGB{N0f8}`). The alpha channel is deliberately ignored here, as a fully transparent white pixel should still be considered "white background" for cropping purposes.
    * For `Gray`, it checks if the gray value is at its maximum.
5.  **`crop_whitespace` function**:
    * **Loading**: `img = FileIO.load(input_path)` loads the image.
    * **Pixel Access**: `img[r, c]` directly accesses the pixel at row `r` and column `c`. The `Images` package handles different underlying storage types.
    * **Finding Boundaries**:
        * It iterates through each pixel of the image.
        * `min_r`, `max_r`, `min_c`, `max_c` are initialized to find the smallest and largest row and column indices that contain a non-background pixel.
        * The `check_pixel_is_background` function is used here. If `target_color` is `nothing`, it defaults to `is_white`. Otherwise, it checks if the pixel is exactly equal to `target_color`.
    * **No Content**: If `found_content` remains `false`, it means the image is entirely the background color (or empty), so it saves the original image and issues a warning.
    * **Padding**: The `padding` argument is used to extend the bounding box. `max(1, ...)` and `min(height/width, ...)` ensure the padded box doesn't go outside the original image dimensions.
    * **Cropping**: `cropped_img = img[min_r:max_r, min_c:max_c]` performs the actual crop. Julia's array slicing is very convenient for this.
    * **Saving**: `FileIO.save(output_path, cropped_img)` saves the result.
    * **Error Handling**: A `try-catch` block is used to catch potential errors during file I/O or image processing.

This module should provide a robust way to crop whitespace from your exported plots or any other PNG images. Let me know if you have any questions or modifications!

This package is create on 2025-05-22.
