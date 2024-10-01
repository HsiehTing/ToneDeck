//
//  Shader.metal
//  ToneDeck
//
//  Created by 謝霆 on 2024/10/1.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
[[ stitchable ]] half4 pixellate(float2 position, SwiftUI::Layer layer, float strength) {
    float min_strength = metal::max(strength, 0.0001);
    float coord_x = min_strength * metal::round(position.x / min_strength);
    float coord_y = min_strength * metal::round(position.y / min_strength);
    return layer.sample(float2(coord_x, coord_y));
}
using namespace metal;


