Shader "Custom/Class Toon Shader"
{
    Properties
    {
        // --- Main Textures & Colors ---
        _Color ("Color", Color) = (1,1,1,1)
        _Color2 ("Alternate Color", Color) = (1,1,1,1)
        _LerpAlpha ("Transition Value", Range(0,1)) = 0.0
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}

        // --- Toon Settings ---
        _RampText ("Ramp Texture (Lighting)", 2D) = "white" {}
        
        // --- Outline Settings ---
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineSize ("Outline Size", Range(0,0.1)) = 0.01
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        // ========================================================
        // PASS 1: THE OUTLINE
        // (Inverted Hull Technique)
        // ========================================================
        Pass 
        {
            Name "Outline"
            Cull Front // Draw the back faces (inside out)
            ZWrite On
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            float _OutlineSize;
            fixed4 _OutlineColor;

            v2f vert (appdata v) 
            {
                v2f o;
                // Move vertex along its normal direction
                float3 norm = normalize(v.normal);
                float3 offset = norm * _OutlineSize;
                
                // Transform to clip space
                o.pos = UnityObjectToClipPos(v.vertex + offset);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target 
            {
                return _OutlineColor;
            }
            ENDCG
        }

        // ========================================================
        // PASS 2: MAIN SURFACE SHADER (CEL SHADING)
        // ========================================================
        CGPROGRAM
        // We use a custom lighting model named "ToonRamp" instead of "Standard"
        #pragma surface surf ToonRamp fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _RampText;
        
        fixed4 _Color;
        fixed4 _Color2;
        half _LerpAlpha;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        // --- CUSTOM LIGHTING MODEL ---
        // This calculates lighting based on the angle between the normal and light.
        // Instead of a smooth gradient, it looks up the color in the Ramp Texture.
        half4 LightingToonRamp (SurfaceOutput s, half3 lightDir, half atten) 
        {
            // Calculate dot product (How much the surface faces the light)
            float d = dot(s.Normal, lightDir);
            
            // Remap -1..1 to 0..1 for UV coordinates
            float h = d * 0.5 + 0.5;

            // Sample the Ramp Texture based on light angle
            fixed3 ramp = tex2D(_RampText, float2(h, 0.5)).rgb;

            half4 c;
            // Final Color = Surface Color * Light Color * Ramp Color * Shadow/Attenuation
            c.rgb = s.Albedo * _LightColor0.rgb * ramp * atten;
            c.a = s.Alpha;
            return c;
        }

        // --- SURFACE FUNCTION ---
        void surf (Input IN, inout SurfaceOutput o)
        {
            // Mix the two colors based on the slider
            fixed4 cResult = lerp(_Color, _Color2, _LerpAlpha);

            // Apply texture and mixed color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * cResult;
            
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }
        ENDCG
    }
    FallBack "Diffuse"
}