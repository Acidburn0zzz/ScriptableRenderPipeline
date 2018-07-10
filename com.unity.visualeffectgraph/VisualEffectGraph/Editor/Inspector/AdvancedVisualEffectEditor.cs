using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Experimental;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Experimental.VFX;

using UnityEditor.VFX;
using UnityEditor.VFX.UI;
using UnityEditor.Experimental.UIElements.GraphView;
using EditMode = UnityEditorInternal.EditMode;
using UnityObject = UnityEngine.Object;
using System.Reflection;
namespace UnityEditor.VFX
{
    static class VisualEffectSerializationUtility
    {
        public static string GetTypeField(Type type)
        {
            if (type == typeof(Vector2))
            {
                return "m_Vector2f";
            }
            else if (type == typeof(Vector3))
            {
                return "m_Vector3f";
            }
            else if (type == typeof(Vector4))
            {
                return "m_Vector4f";
            }
            else if (type == typeof(Color))
            {
                return "m_Vector4f";
            }
            else if (type == typeof(AnimationCurve))
            {
                return "m_AnimationCurve";
            }
            else if (type == typeof(Gradient))
            {
                return "m_Gradient";
            }
            else if (type == typeof(Texture2D))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(Texture2DArray))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(Texture3D))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(Cubemap))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(CubemapArray))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(Mesh))
            {
                return "m_NamedObject";
            }
            else if (type == typeof(float))
            {
                return "m_Float";
            }
            else if (type == typeof(int))
            {
                return "m_Int";
            }
            else if (type == typeof(uint))
            {
                return "m_Uint";
            }
            else if (type == typeof(bool))
            {
                return "m_Bool";
            }
            else if (type == typeof(Matrix4x4))
            {
                return "m_Matrix4x4f";
            }
            //Debug.LogError("unknown vfx property type:"+type.UserFriendlyName());
            return null;
        }
    }

    [CustomEditor(typeof(VisualEffect))]
    [CanEditMultipleObjects]
    public class AdvancedVisualEffectEditor : VisualEffectEditor, IToolModeOwner
    {
        new void OnEnable()
        {
            base.OnEnable();
            EditMode.editModeStarted += OnEditModeStart;
            EditMode.editModeEnded += OnEditModeEnd;

            // Force rebuilding the parameterinfos
            VisualEffect effect = ((VisualEffect)targets[0]);

            var asset = effect.visualEffectAsset;
            if (asset != null && asset.GetResource() != null)
            {
                var graph = asset.GetResource().GetOrCreateGraph();

                if (graph)
                {
                    graph.BuildParameterInfo();
                }
            }
        }

        new void OnDisable()
        {
            VisualEffect effect = ((VisualEffect)targets[0]);
            // Check if the component is attach in the editor. If So do not call base.OnDisable() because we don't want to reset the playrate or pause
            VFXViewWindow window = VFXViewWindow.currentWindow;
            if (window == null || window.graphView == null || window.graphView.attachedComponent != effect)
            {
                base.OnDisable();
            }

            m_ContextsPerComponent.Clear();
            EditMode.editModeStarted -= OnEditModeStart;
            EditMode.editModeEnded -= OnEditModeEnd;
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
        }

        void OnEditModeStart(IToolModeOwner owner, EditMode.SceneViewEditMode mode)
        {
            if (mode == EditMode.SceneViewEditMode.Collider && owner == (IToolModeOwner)this)
                OnEditStart();
        }

        void OnEditModeEnd(IToolModeOwner owner)
        {
            if (owner == (IToolModeOwner)this)
                OnEditEnd();
        }

        protected override void AssetField()
        {
            var component = (VisualEffect)target;
            using (new GUILayout.HorizontalScope())
            {
                EditorGUILayout.PropertyField(m_VisualEffectAsset, Contents.assetPath);

                GUI.enabled = component.visualEffectAsset != null; // Enabled state will be kept for all content until the end of the inspectorGUI.
                if (GUILayout.Button(Contents.openEditor, EditorStyles.miniButton, Styles.MiniButtonWidth))
                {
                    VFXViewWindow window = EditorWindow.GetWindow<VFXViewWindow>();

                    window.LoadAsset(component.visualEffectAsset, component);
                }
            }
        }

        protected override void EditorModeInspectorButton()
        {
            EditMode.DoEditModeInspectorModeButton(
                EditMode.SceneViewEditMode.Collider,
                "Show Parameters",
                EditorGUIUtility.IconContent("EditCollider"),
                this
                );
        }

        VFXParameter GetParameter(string name)
        {
            VisualEffect effect = (VisualEffect)target;

            if (effect.visualEffectAsset == null)
                return null;

            VFXGraph graph = effect.visualEffectAsset.GetResource().graph as VFXGraph;
            if (graph == null)
                return null;

            var parameter = graph.children.OfType<VFXParameter>().FirstOrDefault(t => t.exposedName == name && t.exposed == true);
            if (parameter == null)
                return null;

            return parameter;
        }

        VFXParameter m_GizmoedParameter;

        protected override void EmptyLineControl(string name, int depth)
        {
            if (depth != 1  || !m_GizmoDisplayed)
            {
                base.EmptyLineControl(name, depth);
                return;
            }

            VFXParameter parameter = GetParameter(name);

            if (!VFXGizmoUtility.HasGizmo(parameter.type))
            {
                base.EmptyLineControl(name, depth);
                return;
            }

            if (m_EditJustStarted && m_GizmoedParameter == null)
            {
                m_GizmoedParameter = parameter;
            }

            GUILayout.BeginHorizontal();
            /*bool hasMultipleValue = true;
            m_ParameterHasMultipleValues.TryGetValue(name, out hasMultipleValue);
            GUI.enabled = !hasMultipleValue;

            if (hasMultipleValue && m_GizmoedParameter == parameter)
            {
                m_GizmoedParameter = null;
            }*/

            if (GUILayout.Toggle(m_GizmoedParameter == parameter, new GUIContent(Resources.Load<Texture2D>(EditorGUIUtility.pixelsPerPoint > 1 ? "VFX/gizmos@2x" : "VFX/gizmos")), GetCurrentSkin().button, GUILayout.Width(overrideWidth)))
            {
                m_GizmoedParameter = parameter;
            }

            //GUI.enabled = true;
            EditorGUILayout.LabelField(name);
            GUILayout.EndHorizontal();
        }

        bool m_EditJustStarted;
        bool m_GizmoDisplayed;
        void OnEditStart()
        {
            m_GizmoDisplayed = true;
            m_EditJustStarted = true;
        }

        void OnEditEnd()
        {
            m_GizmoDisplayed = false;
        }

        struct ContextAndGizmo
        {
            public GizmoContext context;
            public VFXGizmo gizmo;
        }


        Dictionary<VisualEffect, ContextAndGizmo> m_ContextsPerComponent = new Dictionary<VisualEffect, ContextAndGizmo>();

        new void OnSceneGUI()
        {
            base.OnSceneGUI();

            if (m_GizmoDisplayed && m_GizmoedParameter != null)
            {
                ContextAndGizmo context;
                //Scene GUI is called every frame for each component in the selection so keep a context and gizmo instance per component
                if (!m_ContextsPerComponent.TryGetValue((VisualEffect)target, out context))
                {
                    context.context = new GizmoContext(new SerializedObject(target), m_GizmoedParameter);
                    context.gizmo = VFXGizmoUtility.CreateGizmoInstance(context.context);
                    m_ContextsPerComponent.Add((VisualEffect)target, context);
                }
                else
                {
                    var prevType = context.context.portType;
                    context.context.SetParameter(m_GizmoedParameter);
                    if (context.context.portType != prevType)
                    {
                        context.gizmo = VFXGizmoUtility.CreateGizmoInstance(context.context);
                        m_ContextsPerComponent[(VisualEffect)target] = context;
                    }
                }

                VFXGizmoUtility.Draw(context.context, (VisualEffect)target, context.gizmo);
            }
        }

        class GizmoContext : VFXGizmoUtility.Context
        {
            public GizmoContext(SerializedObject obj, VFXParameter parameter)
            {
                m_SerializedObject = obj;
                m_Parameter = parameter;
                m_VFXPropertySheet = m_SerializedObject.FindProperty("m_PropertySheet");
            }

            public override System.Type portType
            {
                get {return m_Parameter.type; }
            }

            public override CoordinateSpace space
            {
                get
                {
                    return m_Parameter.outputSlots[0].space;
                }
            }

            public List<object> m_Stack = new List<object>();

            public override object value
            {
                get
                {
                    m_SerializedObject.Update();
                    if (m_Stack.Count == 0)
                        m_Stack.Add(System.Activator.CreateInstance(portType));
                    else
                        m_Stack.RemoveRange(1, m_Stack.Count - 1);
                    int stackSize = m_Stack.Count;

                    foreach (var cmd in m_ValueCmdList)
                    {
                        cmd(m_Stack);
                        stackSize = m_Stack.Count;
                    }


                    return m_Stack[0];
                }
            }

            SerializedObject m_SerializedObject;
            SerializedProperty m_VFXPropertySheet;

            public override VFXGizmo.IProperty<T> RegisterProperty<T>(string memberPath)
            {
                var cmdList = new List<Action<List<object>, object>>();
                bool succeeded = BuildPropertyValue<T>(cmdList, m_Parameter.type, m_Parameter.exposedName, memberPath.Split(new char[] {separator[0]}, StringSplitOptions.RemoveEmptyEntries), 0);
                if (succeeded)
                {
                    return new Property<T>(m_SerializedObject, cmdList);
                }

                return VFXGizmoUtility.NullProperty<T>.defaultProperty;
            }

            bool BuildPropertyValue<T>(List<Action<List<object>, object>> cmdList, Type type, string propertyPath, string[] memberPath, int depth, FieldInfo specialSpacableVector3CaseField = null)
            {
                string field = VisualEffectSerializationUtility.GetTypeField(type);

                if (field != null)
                {
                    var vfxField = m_VFXPropertySheet.FindPropertyRelative(field + ".m_Array");
                    if (vfxField == null)
                        return false;

                    SerializedProperty property = null;
                    if (vfxField != null)
                    {
                        for (int i = 0; i < vfxField.arraySize; ++i)
                        {
                            property = vfxField.GetArrayElementAtIndex(i);
                            var nameProperty = property.FindPropertyRelative("m_Name").stringValue;
                            if (nameProperty == propertyPath)
                            {
                                break;
                            }
                            property = null;
                        }
                    }
                    if (property != null)
                    {
                        SerializedProperty overrideProperty = property.FindPropertyRelative("m_Overridden");
                        property = property.FindPropertyRelative("m_Value");
                        cmdList.Add((l, o) => overrideProperty.boolValue = true);
                    }
                    else
                    {
                        return false;
                    }

                    if (depth < memberPath.Length)
                    {
                        cmdList.Add((l, o) => l.Add(GetObjectValue(property)));
                        if (!BuildPropertySubValue<T>(cmdList, type, memberPath, depth))
                            return false;
                        cmdList.Add((l, o) => SetObjectValue(property, l[l.Count - 1]));

                        return true;
                    }
                    else
                    {
                        var currentValue = GetObjectValue(property);
                        if (specialSpacableVector3CaseField != null)
                        {
                            cmdList.Add(
                                (l, o) => {
                                    object vector3Property = specialSpacableVector3CaseField.GetValue(o);
                                    SetObjectValue(property, vector3Property);
                                });
                        }
                        else
                        {
                            if (!typeof(T).IsAssignableFrom(currentValue.GetType()))
                            {
                                return false;
                            }

                            cmdList.Add((l, o) => SetObjectValue(property, o));
                        }
                        return true;
                    }
                }
                else if (depth < memberPath.Length)
                {
                    FieldInfo subField = type.GetField(memberPath[depth]);
                    if (subField == null)
                        return false;
                    return BuildPropertyValue<T>(cmdList, subField.FieldType, propertyPath + "_" + memberPath[depth], memberPath, depth + 1);
                }
                else if (typeof(Position) == type || typeof(Vector) == type || typeof(DirectionType) == type)
                {
                    if (typeof(T) != type)
                    {
                        return false;
                    }

                    FieldInfo vector3Field = type.GetFields(BindingFlags.Instance | BindingFlags.Public).First(t => t.FieldType == typeof(Vector3));
                    string name = vector3Field.Name;
                    return BuildPropertyValue<T>(cmdList, typeof(Vector3), propertyPath + "_" + name, new string[] {name}, 1, vector3Field);
                }
                Debug.LogError("Setting A value across multiple property is not yet supported");

                return false;
            }

            bool BuildPropertySubValue<T>(List<Action<List<object>, object>> cmdList, Type type, string[] memberPath, int depth)
            {
                FieldInfo subField = type.GetField(memberPath[depth]);
                if (subField == null)
                    return false;

                depth++;
                if (depth < memberPath.Length)
                {
                    cmdList.Add((l, o) => l.Add(subField.GetValue(l[l.Count - 1])));
                    BuildPropertySubValue<T>(cmdList, type, memberPath, depth);
                    cmdList.Add((l, o) => subField.SetValue(l[l.Count - 2], l[l.Count - 1]));
                    cmdList.Add((l, o) => l.RemoveAt(l.Count - 1));
                }
                else
                {
                    if (subField.FieldType != typeof(T))
                        return false;
                    cmdList.Add((l, o) => subField.SetValue(l[l.Count - 1], o));
                }

                return true;
            }

            object GetObjectValue(SerializedProperty prop)
            {
                switch (prop.propertyType)
                {
                    case SerializedPropertyType.Float:
                        return prop.floatValue;
                    case SerializedPropertyType.Vector3:
                        return prop.vector3Value;
                    case SerializedPropertyType.Vector2:
                        return prop.vector2Value;
                    case SerializedPropertyType.Vector4:
                        return prop.vector4Value;
                    //case SerializedPropertyType.ObjectReference:
                    //    return prop.objectReferenceValue;
                    case SerializedPropertyType.Integer:
                        return prop.intValue;
                    case SerializedPropertyType.Boolean:
                        return prop.boolValue;
                        //case SerializedPropertyType.Gradient:
                        //    return prop.gradientValue;
                        //case SerializedPropertyType.AnimationCurve:
                        //    return prop.animationCurveValue;
                }
                return null;
            }

            void SetObjectValue(SerializedProperty prop, object value)
            {
                switch (prop.propertyType)
                {
                    case SerializedPropertyType.Float:
                        prop.floatValue = (float)value;
                        return;
                    case SerializedPropertyType.Vector3:
                        prop.vector3Value = (Vector3)value;
                        return;
                    case SerializedPropertyType.Vector2:
                        prop.vector2Value = (Vector2)value;
                        return;
                    case SerializedPropertyType.Vector4:
                        prop.vector4Value = (Vector4)value;
                        return;
                    //case SerializedPropertyType.ObjectReference:
                    //    prop.objectReferenceValue = (UnityEngine.Object)value;
                    //    return;
                    case SerializedPropertyType.Integer:
                        prop.intValue = (int)value;
                        return;
                    case SerializedPropertyType.Boolean:
                        prop.boolValue = (bool)value;
                        return;
                        //case SerializedPropertyType.Gradient:
                        //    prop.gradientValue = (Gradient)value;
                        //    return;
                        //case SerializedPropertyType.AnimationCurve:
                        //    prop.animationCurveValue = (AnimationCurve)value;
                        //    return;
                }
            }

            public void SetParameter(VFXParameter parameter)
            {
                if (parameter != m_Parameter)
                {
                    Unprepare();
                    m_Parameter = parameter;
                }
            }

            List<Action<List<object>>> m_ValueCmdList = new List<Action<List<object>>>();

            protected override void InternalPrepare()
            {
                m_ValueCmdList.Clear();
                m_Stack.Clear();

                BuildValue(m_ValueCmdList, portType, m_Parameter.exposedName);
            }

            void BuildValue(List<Action<List<object>>> cmdList, Type type, string propertyPath)
            {
                string field = VisualEffectSerializationUtility.GetTypeField(type);
                if (field != null)
                {
                    var vfxField = m_VFXPropertySheet.FindPropertyRelative(field + ".m_Array");
                    SerializedProperty property = null;
                    if (vfxField != null)
                    {
                        for (int i = 0; i < vfxField.arraySize; ++i)
                        {
                            property = vfxField.GetArrayElementAtIndex(i);
                            var nameProperty = property.FindPropertyRelative("m_Name").stringValue;
                            if (nameProperty == propertyPath)
                            {
                                break;
                            }
                            property = null;
                        }
                    }
                    if (property != null)
                    {
                        property = property.FindPropertyRelative("m_Value");


                        //Debug.Log("PushProperty" + propertyPath + "("+property.propertyType.ToString()+")");
                        cmdList.Add(
                            o => PushProperty(o, property)
                            );
                    }
                }
                else
                {
                    foreach (var fieldInfo in type.GetFields(BindingFlags.Public | BindingFlags.Instance))
                    {
                        if (fieldInfo.FieldType == typeof(CoordinateSpace))
                            continue;
                        //Debug.Log("Push "+type.UserFriendlyName()+"."+fieldInfo.Name+"("+fieldInfo.FieldType.UserFriendlyName());
                        cmdList.Add(o =>
                            {
                                Push(o, fieldInfo);
                            });
                        BuildValue(cmdList, fieldInfo.FieldType, propertyPath + "_" + fieldInfo.Name);
                        //Debug.Log("Pop "+type.UserFriendlyName()+"."+fieldInfo.Name+"("+fieldInfo.FieldType.UserFriendlyName());
                        cmdList.Add(o =>
                            Pop(o, fieldInfo)
                            );
                    }
                }
            }

            void PushProperty(List<object> stack, SerializedProperty property)
            {
                stack[stack.Count - 1] = GetObjectValue(property);
            }

            void Push(List<object> stack, FieldInfo fieldInfo)
            {
                object prev = stack[stack.Count - 1];
                stack.Add(fieldInfo.GetValue(prev));
            }

            void Pop(List<object> stack, FieldInfo fieldInfo)
            {
                fieldInfo.SetValue(stack[stack.Count - 2], stack[stack.Count - 1]);
                stack.RemoveAt(stack.Count - 1);
            }

            class Property<T> : VFXGizmo.IProperty<T>
            {
                public Property(SerializedObject serilializedObject, List<Action<List<object>, object>> cmdlist)
                {
                    m_SerializedObject = serilializedObject;
                    m_CmdList = cmdlist;
                }

                public bool isEditable { get {return true; } }


                List<Action<List<object>, object>> m_CmdList;
                List<object> m_Stack = new List<object>();

                SerializedObject m_SerializedObject;

                public void SetValue(T value)
                {
                    m_Stack.Clear();
                    foreach (var cmd in m_CmdList)
                    {
                        cmd(m_Stack, value);
                    }
                    m_SerializedObject.ApplyModifiedProperties();
                }
            }

            VFXParameter m_Parameter;
        }
    }
}
