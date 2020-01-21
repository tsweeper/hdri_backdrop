// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Panoramic" {
Properties {
    _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
    [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
    _Rotation ("Rotation", Range(0, 360)) = 0
    [NoScaleOffset] _Tex ("Spherical  (HDR)", 2D) = "grey" {}
    
    _ProjPos ("Projection Position", Vector) = (0,1.7,0,0)
}

SubShader {
    Tags {
        "PreviewType"="Skybox"
    }
    Cull Off ZWrite Off

    Pass {
    
        // Tags {"LightMode"="ForwardBase"}

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 3.0

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        sampler2D _Tex;
        float4 _Tex_TexelSize;
        half4 _Tex_HDR;
        half4 _Tint;
        half _Exposure;
        float _Rotation;
        int _ImageType;
        
        inline float2 ToRadialCoords(float3 coords)
        {
            float3 normalizedCoords = normalize(coords);
            float latitude = acos(normalizedCoords.y);
            float longitude = atan2(normalizedCoords.z, normalizedCoords.x);
            float2 sphereCoords = float2(longitude, latitude) * float2(0.5/UNITY_PI, 1.0/UNITY_PI);
            return float2(0.5,1.0) - sphereCoords;
        }

        float3 RotateAroundYInDegrees (float3 vertex, float degrees)
        {
            float alpha = degrees * UNITY_PI / 180.0;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            float2x2 m = float2x2(cosa, -sina, sina, cosa);
            return float3(mul(m, vertex.xz), vertex.y).xzy;
        }

        struct v2f {
            float4 pos : SV_POSITION;
            
            float3 worldPos : TEXCOORD0;
            float3 worldNormal : TEXCOORD1;
            
            fixed3 diff : COLOR0;
            fixed3 ambient : COLOR1;
            SHADOW_COORDS(2)
        };

        v2f vert (appdata_base v)
        {
            v2f o;
            float3 rotated = RotateAroundYInDegrees(v.vertex, _Rotation);
            o.pos = UnityObjectToClipPos(rotated);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
            // o.worldNormal = mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz;
            
            half3 worldNormal = UnityObjectToWorldNormal(v.normal);
            o.worldNormal = worldNormal;
            half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
            o.diff = nl * _LightColor0.rgb;
            o.ambient = ShadeSH9(half4(worldNormal,1));
            TRANSFER_SHADOW(o)
            
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float3 worldNormal = normalize(i.worldNormal);
            float3 projNormal = saturate(pow(worldNormal * 1.5, 4));
            
            float2 tc = ToRadialCoords(i.worldPos - _WorldSpaceCameraPos);
            if (tc.x > 1.0)
                return half4(0,0,0,1);
            tc.x = fmod(tc.x * 1, 1);
            
            fixed shadow = SHADOW_ATTENUATION(i);
            fixed3 lighting = i.diff * shadow + i.ambient;
            
            half4 tex = tex2D (_Tex, tc);
            half3 c = DecodeHDR (tex, _Tex_HDR);
            c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
            c *= _Exposure;
            c *= shadow;
                        
            return half4(c, 1);
        }
        ENDCG
    }
    
//    Pass {
//        Tags {
//            "LightMode"="ShadowCaster"
//        }
//        
//        CGPROGRAM
//        #pragma vertex vert
//        #pragma fragment frag
//        #pragma multi_compile_shadowcaster
//        #include "UnityCG.cginc"
//        
//        struct v2f { 
//            V2F_SHADOW_CASTER;
//        };
//
//        v2f vert(appdata_base v)
//        {
//            v2f o;
//            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
//            return o;
//        }
//
//        float4 frag(v2f i) : SV_Target
//        {
//            SHADOW_CASTER_FRAGMENT(i)
//        }
//        ENDCG
//    }
}


//CustomEditor "SkyboxPanoramicBetaShaderGUI"
Fallback Off

}